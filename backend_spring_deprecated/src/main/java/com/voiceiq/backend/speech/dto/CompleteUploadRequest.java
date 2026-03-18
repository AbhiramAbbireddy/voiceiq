package com.voiceiq.backend.speech.dto;

import jakarta.validation.constraints.NotBlank;

public record CompleteUploadRequest(
        @NotBlank(message = "Object key is required")
        String objectKey,
        @NotBlank(message = "Original file name is required")
        String originalFileName,
        @NotBlank(message = "Mime type is required")
        String mimeType,
        Integer durationSeconds
) {
}
