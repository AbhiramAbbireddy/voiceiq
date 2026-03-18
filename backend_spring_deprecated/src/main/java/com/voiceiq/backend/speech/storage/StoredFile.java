package com.voiceiq.backend.speech.storage;

public record StoredFile(
        String storageUrl,
        String objectKey,
        String localPath,
        String originalFileName,
        long fileSizeBytes,
        String mimeType
) {
}
