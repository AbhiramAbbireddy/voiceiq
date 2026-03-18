package com.voiceiq.backend.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "voiceiq.defaults")
public record VoiceIqDefaultsProperties(
        int sampleReportScore,
        int samplePaceScore,
        int sampleClarityScore,
        int sampleConfidenceScore,
        int sampleFillerScore
) {
}
