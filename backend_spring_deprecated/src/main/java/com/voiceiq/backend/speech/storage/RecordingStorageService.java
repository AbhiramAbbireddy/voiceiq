package com.voiceiq.backend.speech.storage;

import com.voiceiq.backend.common.exception.BadRequestException;
import org.springframework.web.multipart.MultipartFile;

import java.util.UUID;

public interface RecordingStorageService {
    StoredFile store(UUID sessionId, MultipartFile file);

    default DirectUploadPreparation initiateDirectUpload(UUID sessionId, String originalFileName, String mimeType) {
        throw new BadRequestException("Direct upload is not supported for the current storage provider");
    }

    default StoredFile completeDirectUpload(UUID sessionId, DirectUploadCompletion completion) {
        throw new BadRequestException("Direct upload completion is not supported for the current storage provider");
    }
}
