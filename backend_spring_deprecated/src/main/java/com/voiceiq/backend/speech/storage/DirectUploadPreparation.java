package com.voiceiq.backend.speech.storage;

import java.util.Map;

public record DirectUploadPreparation(
        String uploadType,
        String uploadUrl,
        String objectKey,
        String storageUrl,
        Map<String, String> requiredHeaders
) {
}
