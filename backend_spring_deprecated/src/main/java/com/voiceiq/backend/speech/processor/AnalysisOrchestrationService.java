package com.voiceiq.backend.speech.processor;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.voiceiq.backend.common.exception.NotFoundException;
import com.voiceiq.backend.feedback.domain.FeedbackReport;
import com.voiceiq.backend.feedback.repository.FeedbackReportRepository;
import com.voiceiq.backend.progress.domain.ProgressScore;
import com.voiceiq.backend.progress.repository.ProgressScoreRepository;
import com.voiceiq.backend.speech.domain.InterviewSession;
import com.voiceiq.backend.speech.domain.Recording;
import com.voiceiq.backend.speech.domain.SessionStatus;
import com.voiceiq.backend.speech.domain.Transcript;
import com.voiceiq.backend.speech.repository.InterviewSessionRepository;
import com.voiceiq.backend.speech.repository.RecordingRepository;
import com.voiceiq.backend.speech.repository.TranscriptRepository;
import com.voiceiq.backend.speech.transcription.SpeechTranscriptionService;
import com.voiceiq.backend.speech.transcription.TranscriptionResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
public class AnalysisOrchestrationService {

    private static final Logger log = LoggerFactory.getLogger(AnalysisOrchestrationService.class);

    private final InterviewSessionRepository sessionRepository;
    private final RecordingRepository recordingRepository;
    private final TranscriptRepository transcriptRepository;
    private final FeedbackReportRepository feedbackReportRepository;
    private final ProgressScoreRepository progressScoreRepository;
    private final SpeechAnalysisProcessor speechAnalysisProcessor;
    private final SpeechTranscriptionService speechTranscriptionService;
    private final ObjectMapper objectMapper;

    public AnalysisOrchestrationService(
            InterviewSessionRepository sessionRepository,
            RecordingRepository recordingRepository,
            TranscriptRepository transcriptRepository,
            FeedbackReportRepository feedbackReportRepository,
            ProgressScoreRepository progressScoreRepository,
            SpeechAnalysisProcessor speechAnalysisProcessor,
            SpeechTranscriptionService speechTranscriptionService
    ) {
        this.sessionRepository = sessionRepository;
        this.recordingRepository = recordingRepository;
        this.transcriptRepository = transcriptRepository;
        this.feedbackReportRepository = feedbackReportRepository;
        this.progressScoreRepository = progressScoreRepository;
        this.speechAnalysisProcessor = speechAnalysisProcessor;
        this.speechTranscriptionService = speechTranscriptionService;
        this.objectMapper = new ObjectMapper();
    }

    @Transactional
    public void processSession(UUID sessionId) {
        log.info("Processing analysis for session {}", sessionId);

        InterviewSession session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new NotFoundException("Session not found"));
        Recording recording = recordingRepository.findBySession_Id(sessionId)
                .orElseThrow(() -> new NotFoundException("Recording not found"));

        try {
            session.setStatus(SessionStatus.PROCESSING);
            sessionRepository.save(session);
            log.info("Session {} moved to PROCESSING", sessionId);

            TranscriptionResult transcriptionResult = speechTranscriptionService.transcribe(session, recording);
            log.info("Transcription finished for session {} using provider {}", sessionId, transcriptionResult.provider());
            SpeechAnalysisResult analysisResult = speechAnalysisProcessor.analyze(
                    session,
                    recording,
                    transcriptionResult.transcriptText()
            );

            Transcript transcript = transcriptRepository.findBySession_Id(session.getId())
                    .orElseGet(() -> {
                        Transcript newTranscript = new Transcript();
                        newTranscript.setId(UUID.randomUUID());
                        newTranscript.setSession(session);
                        return newTranscript;
                    });
            transcript.setTranscriptText(analysisResult.transcriptText());
            transcript.setFillerCount(analysisResult.fillerCount());
            transcript.setWordsPerMinute(analysisResult.wordsPerMinute());
            transcript.setHighlightsJson(writeHighlights(analysisResult.transcriptHighlights()));
            transcriptRepository.save(transcript);

            FeedbackReport feedbackReport = feedbackReportRepository.findBySession_Id(session.getId())
                    .orElseGet(() -> {
                        FeedbackReport newReport = new FeedbackReport();
                        newReport.setId(UUID.randomUUID());
                        newReport.setSession(session);
                        return newReport;
                    });
            feedbackReport.setOverallScore(analysisResult.overallScore());
            feedbackReport.setPaceScore(analysisResult.paceScore());
            feedbackReport.setClarityScore(analysisResult.clarityScore());
            feedbackReport.setConfidenceScore(analysisResult.confidenceScore());
            feedbackReport.setFillerScore(analysisResult.fillerScore());
            feedbackReport.setSummary(analysisResult.summary());
            feedbackReport.setStrengths(joinList(analysisResult.strengths()));
            feedbackReport.setWeaknesses(joinList(analysisResult.weaknesses()));
            feedbackReport.setSuggestions(joinList(analysisResult.suggestions()));
            feedbackReport.setBetterAnswer(analysisResult.betterAnswer());
            feedbackReport.setFillerBreakdown(joinList(analysisResult.fillerBreakdown()));
            feedbackReport.setHesitationPhrases(joinList(analysisResult.hesitationPhrases()));
            feedbackReportRepository.save(feedbackReport);

            int previousScore = progressScoreRepository.findTop30ByUser_IdOrderByCreatedAtDesc(session.getUser().getId())
                    .stream()
                    .findFirst()
                    .map(ProgressScore::getOverallScore)
                    .orElse(analysisResult.overallScore() - 4);

            ProgressScore progressScore = progressScoreRepository.findBySession_Id(session.getId())
                    .orElseGet(() -> {
                        ProgressScore newProgressScore = new ProgressScore();
                        newProgressScore.setId(UUID.randomUUID());
                        newProgressScore.setUser(session.getUser());
                        newProgressScore.setSession(session);
                        return newProgressScore;
                    });
            progressScore.setOverallScore(analysisResult.overallScore());
            progressScore.setImprovementDelta(analysisResult.overallScore() - previousScore);
            progressScoreRepository.save(progressScore);

            session.setStatus(SessionStatus.COMPLETED);
            sessionRepository.save(session);
            log.info("Session {} moved to COMPLETED", sessionId);
        } catch (Exception exception) {
            log.error("Processing failed for session {}", sessionId, exception);
            throw exception;
        }
    }

    private String joinList(java.util.List<String> values) {
        return values == null || values.isEmpty() ? "" : String.join("||", values);
    }

    private String writeHighlights(java.util.List<TranscriptHighlight> highlights) {
        try {
            return highlights == null || highlights.isEmpty() ? "[]" : objectMapper.writeValueAsString(highlights);
        } catch (Exception exception) {
            throw new IllegalStateException("Unable to serialize transcript highlights", exception);
        }
    }
}
