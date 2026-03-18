package com.voiceiq.backend.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "gemini")
public record GeminiProperties(
        boolean enabled,
        String apiKey,
        String baseUrl,
        String model) {
}
