package com.voiceiq.backend.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "whisper")
public record WhisperProperties(
        boolean enabled,
        String serviceUrl
) {
}
