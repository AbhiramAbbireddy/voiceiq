package com.voiceiq.backend.speech.dto;

import com.voiceiq.backend.speech.domain.SessionStatus;

import java.time.LocalDateTime;
import java.util.UUID;

public record RecordingUploadResponse(
        UUID sessionId,
        UUID recordingId,
        SessionStatus status,
        String storageUrl,
        String originalFileName,
        long fileSizeBytes,
        int durationSeconds,
        LocalDateTime uploadedAt
) {
}
