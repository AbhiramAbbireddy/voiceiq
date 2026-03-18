package com.voiceiq.backend.speech.storage;

import com.voiceiq.backend.common.exception.BadRequestException;
import com.voiceiq.backend.config.RecordingStorageProperties;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.UUID;

@Service
@ConditionalOnProperty(prefix = "voiceiq.storage", name = "provider", havingValue = "local", matchIfMissing = true)
public class LocalRecordingStorageService implements RecordingStorageService {

    private final RecordingStorageProperties storageProperties;

    public LocalRecordingStorageService(RecordingStorageProperties storageProperties) {
        this.storageProperties = storageProperties;
    }

    @Override
    public StoredFile store(UUID sessionId, MultipartFile file) {
        if (file.isEmpty()) {
            throw new BadRequestException("Audio file is required");
        }

        String originalFilename = StringUtils.cleanPath(file.getOriginalFilename() == null ? "recording.m4a" : file.getOriginalFilename());
        String sanitizedName = originalFilename.replaceAll("[^a-zA-Z0-9._-]", "_");
        String storedFileName = sessionId + "-" + sanitizedName;

        try {
            Path rootDirectory = Path.of(storageProperties.localDirectory()).toAbsolutePath().normalize();
            Files.createDirectories(rootDirectory);

            Path targetPath = rootDirectory.resolve(storedFileName).normalize();
            Files.copy(file.getInputStream(), targetPath, StandardCopyOption.REPLACE_EXISTING);

            String storageUrl = storageProperties.localRootUrl() + "/" + storedFileName;
            String mimeType = file.getContentType() == null || file.getContentType().isBlank()
                    ? "audio/m4a"
                    : file.getContentType();

            return new StoredFile(
                    storageUrl,
                    null,
                    targetPath.toString(),
                    originalFilename,
                    file.getSize(),
                    mimeType
            );
        } catch (IOException exception) {
            throw new BadRequestException("Unable to store uploaded recording");
        }
    }
}
