package com.voiceiq.backend.speech.dto;

import com.voiceiq.backend.speech.domain.SessionStatus;
import com.voiceiq.backend.speech.domain.SessionType;

import java.time.LocalDateTime;
import java.util.UUID;

public record SessionResponse(
        UUID sessionId,
        UUID userId,
        SessionType type,
        SessionStatus status,
        String promptText,
        String storageUrl,
        int durationSeconds,
        Long fileSizeBytes,
        Integer fillerCount,
        Integer wordsPerMinute,
        LocalDateTime createdAt
) {
}
