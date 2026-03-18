package com.voiceiq.backend.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "voiceiq.storage")
public record RecordingStorageProperties(
        String provider,
        String localRootUrl,
        String localDirectory,
        Integer uploadUrlExpiryMinutes,
        S3Properties s3
) {
    public record S3Properties(
            String bucket,
            String region,
            String keyPrefix,
            String endpointOverride,
            String publicBaseUrl
    ) {
    }
}
