package com.voiceiq.backend.feedback.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.voiceiq.backend.auth.security.CurrentUserService;
import com.voiceiq.backend.common.exception.ConflictException;
import com.voiceiq.backend.speech.domain.InterviewSession;
import com.voiceiq.backend.speech.domain.SessionStatus;
import com.voiceiq.backend.speech.domain.Transcript;
import com.voiceiq.backend.speech.processor.TranscriptHighlight;
import com.voiceiq.backend.speech.repository.InterviewSessionRepository;
import com.voiceiq.backend.speech.repository.TranscriptRepository;
import com.voiceiq.backend.common.exception.NotFoundException;
import com.voiceiq.backend.feedback.domain.FeedbackReport;
import com.voiceiq.backend.feedback.dto.FeedbackReportResponse;
import com.voiceiq.backend.feedback.dto.TranscriptHighlightResponse;
import com.voiceiq.backend.feedback.repository.FeedbackReportRepository;
import org.springframework.stereotype.Service;

import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.UUID;

@Service
public class FeedbackService {

    private final FeedbackReportRepository feedbackReportRepository;
    private final InterviewSessionRepository interviewSessionRepository;
    private final CurrentUserService currentUserService;
    private final TranscriptRepository transcriptRepository;
    private final ObjectMapper objectMapper;

    public FeedbackService(
            FeedbackReportRepository feedbackReportRepository,
            InterviewSessionRepository interviewSessionRepository,
            CurrentUserService currentUserService,
            TranscriptRepository transcriptRepository
    ) {
        this.feedbackReportRepository = feedbackReportRepository;
        this.interviewSessionRepository = interviewSessionRepository;
        this.currentUserService = currentUserService;
        this.transcriptRepository = transcriptRepository;
        this.objectMapper = new ObjectMapper();
    }

    public FeedbackReportResponse getReportForSession(UUID sessionId) {
        InterviewSession session = interviewSessionRepository.findById(sessionId)
                .orElseThrow(() -> new NotFoundException("Session not found"));
        if (!session.getUser().getId().equals(currentUserService.requireCurrentUser().userId())) {
            throw new NotFoundException("Session not found");
        }

        if (session.getStatus() != SessionStatus.COMPLETED) {
            throw new ConflictException("Feedback report is not ready yet. Poll the session status and try again.");
        }

        FeedbackReport report = feedbackReportRepository.findBySession_Id(sessionId)
                .orElseThrow(() -> new NotFoundException("Feedback report not found"));
        Transcript transcript = transcriptRepository.findBySession_Id(sessionId)
                .orElseThrow(() -> new NotFoundException("Transcript not found"));

        return new FeedbackReportResponse(
                report.getId(),
                report.getSession().getId(),
                report.getOverallScore(),
                report.getPaceScore(),
                report.getClarityScore(),
                report.getConfidenceScore(),
                report.getFillerScore(),
                transcript.getTranscriptText(),
                readHighlights(transcript.getHighlightsJson()),
                report.getSummary(),
                split(report.getStrengths()),
                split(report.getWeaknesses()),
                split(report.getSuggestions()),
                report.getBetterAnswer(),
                split(report.getFillerBreakdown()),
                split(report.getHesitationPhrases()),
                report.getCreatedAt()
        );
    }

    private List<String> split(String value) {
        if (value == null || value.isBlank()) {
            return Collections.emptyList();
        }
        return Arrays.stream(value.split("\\|\\|"))
                .map(String::trim)
                .filter(item -> !item.isBlank())
                .toList();
    }

    private List<TranscriptHighlightResponse> readHighlights(String highlightsJson) {
        if (highlightsJson == null || highlightsJson.isBlank()) {
            return Collections.emptyList();
        }

        try {
            return objectMapper.readValue(highlightsJson, new TypeReference<List<TranscriptHighlight>>() {})
                    .stream()
                    .map(highlight -> new TranscriptHighlightResponse(
                            highlight.type(),
                            highlight.value(),
                            highlight.startIndex(),
                            highlight.endIndex(),
                            highlight.message()
                    ))
                    .toList();
        } catch (Exception exception) {
            return Collections.emptyList();
        }
    }
}
