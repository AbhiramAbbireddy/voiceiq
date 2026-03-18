package com.voiceiq.backend.speech.dto;

import com.voiceiq.backend.speech.domain.SessionStatus;

import java.time.LocalDateTime;
import java.util.UUID;

public record SessionStatusResponse(
        UUID sessionId,
        SessionStatus status,
        boolean reportReady,
        boolean transcriptReady,
        String message,
        LocalDateTime updatedAt
) {
}
