package com.voiceiq.backend.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "openai")
public record OpenAiProperties(
        boolean enabled,
        String apiKey,
        String baseUrl,
        String whisperUrl,
        String transcriptionModel,
        String feedbackModel
) {
}
