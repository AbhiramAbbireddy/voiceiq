package com.voiceiq.backend.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.util.List;

@ConfigurationProperties(prefix = "voiceiq.developer")
public record DeveloperAccessProperties(
        List<String> emails
) {
    public DeveloperAccessProperties {
        emails = emails == null ? List.of() : emails.stream()
                .map(String::trim)
                .map(String::toLowerCase)
                .filter(email -> !email.isBlank())
                .distinct()
                .toList();
    }
}
