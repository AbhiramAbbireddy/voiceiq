package com.voiceiq.backend.speech.storage;

public record DirectUploadCompletion(
        String objectKey,
        String originalFileName,
        String mimeType
) {
}
