package com.voiceiq.backend.speech.dto;

import com.voiceiq.backend.speech.domain.SessionType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record CreateSessionRequest(
        @NotNull(message = "Session type is required")
        SessionType type,
        @NotBlank(message = "Prompt text is required")
        String promptText,
        String storageUrl,
        Integer durationSeconds,
        String mimeType
) {
}
