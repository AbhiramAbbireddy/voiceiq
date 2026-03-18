package com.voiceiq.backend.speech.service;

import com.voiceiq.backend.auth.domain.User;
import com.voiceiq.backend.auth.repository.UserRepository;
import com.voiceiq.backend.auth.security.AuthenticatedUser;
import com.voiceiq.backend.auth.security.CurrentUserService;
import com.voiceiq.backend.common.exception.BadRequestException;
import com.voiceiq.backend.common.exception.NotFoundException;
import com.voiceiq.backend.config.RecordingStorageProperties;
import com.voiceiq.backend.feedback.repository.FeedbackReportRepository;
import com.voiceiq.backend.speech.domain.InterviewSession;
import com.voiceiq.backend.speech.domain.Recording;
import com.voiceiq.backend.speech.domain.SessionStatus;
import com.voiceiq.backend.speech.domain.Transcript;
import com.voiceiq.backend.speech.dto.CompleteUploadRequest;
import com.voiceiq.backend.speech.dto.CreateSessionRequest;
import com.voiceiq.backend.speech.dto.InitiateUploadRequest;
import com.voiceiq.backend.speech.dto.InitiateUploadResponse;
import com.voiceiq.backend.speech.dto.RecordingUploadResponse;
import com.voiceiq.backend.speech.dto.SessionResponse;
import com.voiceiq.backend.speech.dto.SessionStatusResponse;
import com.voiceiq.backend.speech.processor.AnalysisJobDispatcher;
import com.voiceiq.backend.speech.repository.InterviewSessionRepository;
import com.voiceiq.backend.speech.repository.RecordingRepository;
import com.voiceiq.backend.speech.repository.TranscriptRepository;
import com.voiceiq.backend.speech.storage.DirectUploadCompletion;
import com.voiceiq.backend.speech.storage.DirectUploadPreparation;
import com.voiceiq.backend.speech.storage.RecordingStorageService;
import com.voiceiq.backend.speech.storage.StoredFile;
import com.voiceiq.backend.subscription.service.SubscriptionService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class SpeechSessionService {

    private static final Logger log = LoggerFactory.getLogger(SpeechSessionService.class);

    private final UserRepository userRepository;
    private final InterviewSessionRepository sessionRepository;
    private final RecordingRepository recordingRepository;
    private final TranscriptRepository transcriptRepository;
    private final FeedbackReportRepository feedbackReportRepository;
    private final RecordingStorageService recordingStorageService;
    private final AnalysisJobDispatcher analysisJobDispatcher;
    private final RecordingStorageProperties recordingStorageProperties;
    private final CurrentUserService currentUserService;
    private final SubscriptionService subscriptionService;

    public SpeechSessionService(
            UserRepository userRepository,
            InterviewSessionRepository sessionRepository,
            RecordingRepository recordingRepository,
            TranscriptRepository transcriptRepository,
            FeedbackReportRepository feedbackReportRepository,
            RecordingStorageService recordingStorageService,
            AnalysisJobDispatcher analysisJobDispatcher,
            RecordingStorageProperties recordingStorageProperties,
            CurrentUserService currentUserService,
            SubscriptionService subscriptionService
    ) {
        this.userRepository = userRepository;
        this.sessionRepository = sessionRepository;
        this.recordingRepository = recordingRepository;
        this.transcriptRepository = transcriptRepository;
        this.feedbackReportRepository = feedbackReportRepository;
        this.recordingStorageService = recordingStorageService;
        this.analysisJobDispatcher = analysisJobDispatcher;
        this.recordingStorageProperties = recordingStorageProperties;
        this.currentUserService = currentUserService;
        this.subscriptionService = subscriptionService;
    }

    @Transactional
    public SessionResponse createSession(AuthenticatedUser authenticatedUser, CreateSessionRequest request) {
        User user = userRepository.findById(authenticatedUser.userId())
                .orElseThrow(() -> new NotFoundException("User not found"));
        subscriptionService.ensureSubscription(user);
        subscriptionService.assertSessionCreationAllowed(user);

        InterviewSession session = new InterviewSession();
        session.setId(UUID.randomUUID());
        session.setUser(user);
        session.setType(request.type());
        session.setStatus(SessionStatus.CREATED);
        session.setPromptText(request.promptText());
        InterviewSession savedSession = sessionRepository.save(session);

        Recording recording = new Recording();
        recording.setId(UUID.randomUUID());
        recording.setSession(savedSession);
        recording.setStorageUrl(request.storageUrl());
        recording.setDurationSeconds(Math.max(request.durationSeconds() == null ? 0 : request.durationSeconds(), 0));
        recording.setMimeType(request.mimeType() == null || request.mimeType().isBlank() ? "audio/m4a" : request.mimeType());
        recordingRepository.save(recording);
        subscriptionService.recordSessionCreated(user);

        return toResponse(savedSession, recording, null);
    }

    @Transactional
    public InitiateUploadResponse initiateUpload(UUID sessionId, InitiateUploadRequest request) {
        InterviewSession session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new NotFoundException("Session not found"));
        Recording recording = recordingRepository.findBySession_Id(sessionId)
                .orElseThrow(() -> new NotFoundException("Recording slot not found"));

        ensureUploadAllowed(session);

        if ("s3".equalsIgnoreCase(recordingStorageProperties.provider())) {
            DirectUploadPreparation preparation = recordingStorageService.initiateDirectUpload(
                    sessionId,
                    request.originalFileName(),
                    request.mimeType()
            );

            recording.setObjectKey(preparation.objectKey());
            recording.setOriginalFileName(request.originalFileName());
            recording.setMimeType(request.mimeType());
            recording.setStorageUrl(preparation.storageUrl());
            recordingRepository.save(recording);

            return new InitiateUploadResponse(
                    session.getId(),
                    recording.getId(),
                    preparation.uploadType(),
                    preparation.uploadUrl(),
                    preparation.objectKey(),
                    preparation.storageUrl(),
                    preparation.requiredHeaders()
            );
        }

        String uploadUrl = "/api/v1/speech/sessions/" + sessionId + "/recording";
        return new InitiateUploadResponse(
                session.getId(),
                recording.getId(),
                "BACKEND_MULTIPART",
                uploadUrl,
                null,
                recording.getStorageUrl(),
                Map.of()
        );
    }

    @Transactional
    public RecordingUploadResponse completeUpload(UUID sessionId, CompleteUploadRequest request) {
        InterviewSession session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new NotFoundException("Session not found"));
        Recording recording = recordingRepository.findBySession_Id(sessionId)
                .orElseThrow(() -> new NotFoundException("Recording slot not found"));

        ensureUploadAllowed(session);

        StoredFile storedFile = recordingStorageService.completeDirectUpload(
                sessionId,
                new DirectUploadCompletion(
                        request.objectKey(),
                        request.originalFileName(),
                        request.mimeType()
                )
        );

        return finalizeUploadedRecording(session, recording, storedFile, request.durationSeconds(), request.mimeType());
    }

    @Transactional
    public RecordingUploadResponse uploadRecording(UUID sessionId, MultipartFile file, Integer durationSeconds, String mimeType) {
        InterviewSession session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new NotFoundException("Session not found"));

        Recording recording = recordingRepository.findBySession_Id(sessionId)
                .orElseThrow(() -> new NotFoundException("Recording slot not found"));

        ensureUploadAllowed(session);

        StoredFile storedFile = recordingStorageService.store(sessionId, file);
        return finalizeUploadedRecording(session, recording, storedFile, durationSeconds, mimeType);
    }

    public SessionResponse getSession(UUID sessionId) {
        InterviewSession session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new NotFoundException("Session not found"));
        ensureSessionOwnership(session);
        Recording recording = recordingRepository.findBySession_Id(sessionId)
                .orElseThrow(() -> new NotFoundException("Recording not found"));
        Transcript transcript = transcriptRepository.findBySession_Id(sessionId).orElse(null);
        return toResponse(session, recording, transcript);
    }

    public SessionStatusResponse getSessionStatus(UUID sessionId) {
        InterviewSession session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new NotFoundException("Session not found"));
        ensureSessionOwnership(session);

        boolean transcriptReady = transcriptRepository.findBySession_Id(sessionId).isPresent();
        boolean reportReady = feedbackReportRepository.findBySession_Id(sessionId).isPresent();

        String message = switch (session.getStatus()) {
            case CREATED -> "Session created. Upload audio to begin analysis.";
            case UPLOADED -> "Recording uploaded. Analysis will begin shortly.";
            case PROCESSING -> "Analysis in progress.";
            case FAILED -> "Analysis failed. Please upload again.";
            case COMPLETED -> "Analysis completed successfully.";
        };

        return new SessionStatusResponse(
                session.getId(),
                session.getStatus(),
                reportReady,
                transcriptReady,
                message,
                session.getUpdatedAt()
        );
    }

    public List<SessionResponse> getUserSessions(UUID userId) {
        ensureCurrentUser(userId);
        return sessionRepository.findByUser_IdOrderByCreatedAtDesc(userId)
                .stream()
                .map(session -> {
                    Recording recording = recordingRepository.findBySession_Id(session.getId()).orElseThrow();
                    Transcript transcript = transcriptRepository.findBySession_Id(session.getId()).orElse(null);
                    return toResponse(session, recording, transcript);
                })
                .toList();
    }

    private void ensureUploadAllowed(InterviewSession session) {
        ensureSessionOwnership(session);

        if (session.getStatus() == SessionStatus.PROCESSING) {
            throw new BadRequestException("Session is already being processed");
        }

        if (session.getStatus() == SessionStatus.COMPLETED) {
            throw new BadRequestException("Recording already uploaded and processed for this session");
        }
    }

    private RecordingUploadResponse finalizeUploadedRecording(
            InterviewSession session,
            Recording recording,
            StoredFile storedFile,
            Integer durationSeconds,
            String mimeType
    ) {
        subscriptionService.assertProcessingAllowed(session.getUser(), Math.max(durationSeconds == null ? 0 : durationSeconds, 1));

        recording.setStorageUrl(storedFile.storageUrl());
        recording.setObjectKey(storedFile.objectKey());
        recording.setLocalPath(storedFile.localPath());
        recording.setOriginalFileName(storedFile.originalFileName());
        recording.setFileSizeBytes(storedFile.fileSizeBytes());
        recording.setDurationSeconds(Math.max(durationSeconds == null ? 0 : durationSeconds, 1));
        recording.setMimeType(mimeType == null || mimeType.isBlank() ? storedFile.mimeType() : mimeType);
        recordingRepository.save(recording);
        subscriptionService.recordProcessedSeconds(session.getUser(), recording.getDurationSeconds());

        session.setStatus(SessionStatus.UPLOADED);
        sessionRepository.save(session);

        UUID queuedSessionId = session.getId();
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                log.info("Dispatching analysis job after transaction commit for session {}", queuedSessionId);
                analysisJobDispatcher.dispatch(queuedSessionId);
            }
        });

        return new RecordingUploadResponse(
                session.getId(),
                recording.getId(),
                SessionStatus.UPLOADED,
                recording.getStorageUrl(),
                recording.getOriginalFileName(),
                recording.getFileSizeBytes() == null ? 0L : recording.getFileSizeBytes(),
                recording.getDurationSeconds(),
                LocalDateTime.now()
        );
    }

    private SessionResponse toResponse(InterviewSession session, Recording recording, Transcript transcript) {
        return new SessionResponse(
                session.getId(),
                session.getUser().getId(),
                session.getType(),
                session.getStatus(),
                session.getPromptText(),
                recording.getStorageUrl(),
                recording.getDurationSeconds(),
                recording.getFileSizeBytes(),
                transcript == null ? null : transcript.getFillerCount(),
                transcript == null ? null : transcript.getWordsPerMinute(),
                session.getCreatedAt()
        );
    }

    private void ensureSessionOwnership(InterviewSession session) {
        if (!session.getUser().getId().equals(currentUser().userId())) {
            throw new NotFoundException("Session not found");
        }
    }

    private void ensureCurrentUser(UUID userId) {
        if (!currentUser().userId().equals(userId)) {
            throw new NotFoundException("User not found");
        }
    }

    private AuthenticatedUser currentUser() {
        return currentUserService.requireCurrentUser();
    }
}
