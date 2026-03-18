package com.voiceiq.backend.speech.dto;

import java.util.Map;
import java.util.UUID;

public record InitiateUploadResponse(
        UUID sessionId,
        UUID recordingId,
        String uploadType,
        String uploadUrl,
        String objectKey,
        String storageUrl,
        Map<String, String> requiredHeaders
) {
}
