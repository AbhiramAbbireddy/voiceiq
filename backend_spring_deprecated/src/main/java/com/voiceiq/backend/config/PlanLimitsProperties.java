package com.voiceiq.backend.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "voiceiq.limits")
public record PlanLimitsProperties(
        LimitProfile free,
        LimitProfile pro
) {
    public record LimitProfile(
            Integer monthlySessions,
            Integer monthlyProcessedSeconds
    ) {
    }
}
