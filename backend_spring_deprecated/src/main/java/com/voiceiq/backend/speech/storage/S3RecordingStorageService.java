package com.voiceiq.backend.speech.storage;

import com.voiceiq.backend.common.exception.BadRequestException;
import com.voiceiq.backend.config.RecordingStorageProperties;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.auth.credentials.DefaultCredentialsProvider;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.S3ClientBuilder;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.HeadObjectRequest;
import software.amazon.awssdk.services.s3.model.NoSuchKeyException;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.PresignedPutObjectRequest;
import software.amazon.awssdk.services.s3.presigner.model.PutObjectPresignRequest;

import java.io.IOException;
import java.net.URI;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.time.Duration;
import java.util.Map;
import java.util.UUID;

@Service
@ConditionalOnProperty(prefix = "voiceiq.storage", name = "provider", havingValue = "s3")
public class S3RecordingStorageService implements RecordingStorageService {

    private final RecordingStorageProperties storageProperties;
    private final S3Client s3Client;
    private final S3Presigner s3Presigner;

    public S3RecordingStorageService(RecordingStorageProperties storageProperties) {
        this.storageProperties = storageProperties;
        this.s3Client = buildClient(storageProperties);
        this.s3Presigner = buildPresigner(storageProperties);
    }

    @Override
    public StoredFile store(UUID sessionId, MultipartFile file) {
        if (file.isEmpty()) {
            throw new BadRequestException("Audio file is required");
        }

        String originalFilename = StringUtils.cleanPath(file.getOriginalFilename() == null ? "recording.m4a" : file.getOriginalFilename());
        String sanitizedName = originalFilename.replaceAll("[^a-zA-Z0-9._-]", "_");
        String objectKey = buildObjectKey(sessionId, sanitizedName);

        Path tempFile = copyToTemp(sessionId, sanitizedName, file);

        try {
            String mimeType = file.getContentType() == null || file.getContentType().isBlank()
                    ? "audio/m4a"
                    : file.getContentType();

            PutObjectRequest putObjectRequest = PutObjectRequest.builder()
                    .bucket(requiredBucket())
                    .key(objectKey)
                    .contentType(mimeType)
                    .build();

            s3Client.putObject(putObjectRequest, RequestBody.fromFile(tempFile));

            return new StoredFile(
                    buildStorageUrl(requiredBucket(), objectKey),
                    objectKey,
                    tempFile.toString(),
                    originalFilename,
                    Files.size(tempFile),
                    mimeType
            );
        } catch (IOException exception) {
            throw new BadRequestException("Unable to prepare recording for S3 upload");
        } catch (RuntimeException exception) {
            throw new BadRequestException("Unable to upload recording to S3: " + exception.getMessage());
        }
    }

    @Override
    public DirectUploadPreparation initiateDirectUpload(UUID sessionId, String originalFileName, String mimeType) {
        String sanitizedName = StringUtils.cleanPath(
                originalFileName == null || originalFileName.isBlank() ? "recording.m4a" : originalFileName
        ).replaceAll("[^a-zA-Z0-9._-]", "_");
        String normalizedMimeType = mimeType == null || mimeType.isBlank() ? "audio/m4a" : mimeType;
        String objectKey = buildObjectKey(sessionId, sanitizedName);
        int expiryMinutes = storageProperties.uploadUrlExpiryMinutes() == null || storageProperties.uploadUrlExpiryMinutes() <= 0
                ? 15
                : storageProperties.uploadUrlExpiryMinutes();

        PutObjectRequest putObjectRequest = PutObjectRequest.builder()
                .bucket(requiredBucket())
                .key(objectKey)
                .contentType(normalizedMimeType)
                .build();

        PutObjectPresignRequest presignRequest = PutObjectPresignRequest.builder()
                .signatureDuration(Duration.ofMinutes(expiryMinutes))
                .putObjectRequest(putObjectRequest)
                .build();

        PresignedPutObjectRequest presignedRequest = s3Presigner.presignPutObject(presignRequest);

        return new DirectUploadPreparation(
                "DIRECT_PUT",
                presignedRequest.url().toString(),
                objectKey,
                buildStorageUrl(requiredBucket(), objectKey),
                Map.of("Content-Type", normalizedMimeType)
        );
    }

    @Override
    public StoredFile completeDirectUpload(UUID sessionId, DirectUploadCompletion completion) {
        String objectKey = completion.objectKey();
        if (objectKey == null || objectKey.isBlank()) {
            throw new BadRequestException("Object key is required to complete upload");
        }
        if (!objectKey.startsWith(expectedSessionPrefix(sessionId))) {
            throw new BadRequestException("Object key does not match the target session");
        }

        try {
            var objectMetadata = s3Client.headObject(HeadObjectRequest.builder()
                    .bucket(requiredBucket())
                    .key(objectKey)
                    .build());

            String originalFilename = completion.originalFileName() == null || completion.originalFileName().isBlank()
                    ? extractFileName(objectKey)
                    : completion.originalFileName();
            Path tempFile = prepareDownloadedObject(sessionId, originalFilename);

            s3Client.getObject(
                    GetObjectRequest.builder().bucket(requiredBucket()).key(objectKey).build(),
                    tempFile
            );

            String mimeType = completion.mimeType() == null || completion.mimeType().isBlank()
                    ? objectMetadata.contentType()
                    : completion.mimeType();

            return new StoredFile(
                    buildStorageUrl(requiredBucket(), objectKey),
                    objectKey,
                    tempFile.toString(),
                    originalFilename,
                    objectMetadata.contentLength(),
                    mimeType == null || mimeType.isBlank() ? "audio/m4a" : mimeType
            );
        } catch (NoSuchKeyException exception) {
            throw new BadRequestException("Uploaded object was not found in S3");
        } catch (IOException exception) {
            throw new BadRequestException("Unable to prepare downloaded S3 object");
        } catch (RuntimeException exception) {
            throw new BadRequestException("Unable to finalize S3 upload: " + exception.getMessage());
        }
    }

    private Path copyToTemp(UUID sessionId, String sanitizedName, MultipartFile file) {
        Path tempDirectory = Path.of(storageProperties.localDirectory()).toAbsolutePath().normalize();
        Path tempFile = tempDirectory.resolve(sessionId + "-" + sanitizedName);
        try {
            Files.createDirectories(tempDirectory);
            Files.copy(file.getInputStream(), tempFile, StandardCopyOption.REPLACE_EXISTING);
            return tempFile;
        } catch (IOException exception) {
            throw new BadRequestException("Unable to prepare recording for upload");
        }
    }

    private Path prepareDownloadedObject(UUID sessionId, String originalFilename) throws IOException {
        String sanitizedName = originalFilename.replaceAll("[^a-zA-Z0-9._-]", "_");
        Path tempDirectory = Path.of(storageProperties.localDirectory()).toAbsolutePath().normalize();
        Files.createDirectories(tempDirectory);
        return tempDirectory.resolve(sessionId + "-" + sanitizedName);
    }

    private S3Client buildClient(RecordingStorageProperties storageProperties) {
        RecordingStorageProperties.S3Properties s3 = storageProperties.s3();
        if (s3 == null || s3.region() == null || s3.region().isBlank()) {
            throw new BadRequestException("S3 region is not configured");
        }

        S3ClientBuilder builder = S3Client.builder()
                .region(Region.of(s3.region()))
                .credentialsProvider(DefaultCredentialsProvider.create());

        if (s3.endpointOverride() != null && !s3.endpointOverride().isBlank()) {
            builder.endpointOverride(URI.create(s3.endpointOverride()));
        }

        return builder.build();
    }

    private S3Presigner buildPresigner(RecordingStorageProperties storageProperties) {
        RecordingStorageProperties.S3Properties s3 = storageProperties.s3();
        S3Presigner.Builder builder = S3Presigner.builder()
                .region(Region.of(s3.region()))
                .credentialsProvider(DefaultCredentialsProvider.create());

        if (s3.endpointOverride() != null && !s3.endpointOverride().isBlank()) {
            builder.endpointOverride(URI.create(s3.endpointOverride()));
        }

        return builder.build();
    }

    private String buildObjectKey(UUID sessionId, String sanitizedName) {
        String prefix = storageProperties.s3().keyPrefix();
        if (prefix == null || prefix.isBlank()) {
            prefix = "recordings";
        }
        String normalizedPrefix = prefix.endsWith("/") ? prefix.substring(0, prefix.length() - 1) : prefix;
        return normalizedPrefix + "/" + sessionId + "/" + sanitizedName;
    }

    private String expectedSessionPrefix(UUID sessionId) {
        String prefix = storageProperties.s3().keyPrefix();
        if (prefix == null || prefix.isBlank()) {
            prefix = "recordings";
        }
        String normalizedPrefix = prefix.endsWith("/") ? prefix.substring(0, prefix.length() - 1) : prefix;
        return normalizedPrefix + "/" + sessionId + "/";
    }

    private String buildStorageUrl(String bucket, String objectKey) {
        String publicBaseUrl = storageProperties.s3().publicBaseUrl();
        if (publicBaseUrl != null && !publicBaseUrl.isBlank()) {
            String normalizedBase = publicBaseUrl.endsWith("/") ? publicBaseUrl.substring(0, publicBaseUrl.length() - 1) : publicBaseUrl;
            return normalizedBase + "/" + objectKey;
        }

        return "https://" + bucket + ".s3." + storageProperties.s3().region() + ".amazonaws.com/" + objectKey;
    }

    private String requiredBucket() {
        String bucket = storageProperties.s3().bucket();
        if (bucket == null || bucket.isBlank()) {
            throw new BadRequestException("S3 bucket is not configured");
        }
        return bucket;
    }

    private String extractFileName(String objectKey) {
        int separatorIndex = objectKey.lastIndexOf('/');
        return separatorIndex >= 0 ? objectKey.substring(separatorIndex + 1) : objectKey;
    }
}
