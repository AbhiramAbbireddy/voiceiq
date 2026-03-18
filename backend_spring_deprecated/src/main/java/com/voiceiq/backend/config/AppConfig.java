package com.voiceiq.backend.config;

import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.nio.file.Path;

@Configuration
@EnableConfigurationProperties({
        JwtProperties.class,
        OpenAiProperties.class,
        WhisperProperties.class,
        GeminiProperties.class,
        VoiceIqDefaultsProperties.class,
        RecordingStorageProperties.class,
        AnalysisQueueProperties.class,
        PlanLimitsProperties.class,
        DeveloperAccessProperties.class
})
public class AppConfig implements WebMvcConfigurer {

    private final RecordingStorageProperties recordingStorageProperties;

    public AppConfig(RecordingStorageProperties recordingStorageProperties) {
        this.recordingStorageProperties = recordingStorageProperties;
    }

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        if (!"local".equalsIgnoreCase(recordingStorageProperties.provider())) {
            return;
        }

        String localDirectory = Path.of(recordingStorageProperties.localDirectory())
                .toAbsolutePath()
                .normalize()
                .toUri()
                .toString();
        String resourceLocation = localDirectory.endsWith("/") ? localDirectory : localDirectory + "/";

        registry.addResourceHandler("/uploads/**")
                .addResourceLocations(resourceLocation);
    }
}
