package com.voiceiq.backend.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "voiceiq.analysis")
public record AnalysisQueueProperties(
        String dispatcher,
        String exchange,
        String queue,
        String routingKey,
        String retryQueue,
        String retryRoutingKey,
        String deadLetterQueue,
        String deadLetterRoutingKey,
        Integer retryDelayMs,
        Integer maxAttempts
) {
}
