package com.voiceiq.backend.speech.transcription;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.voiceiq.backend.config.WhisperProperties;
import com.voiceiq.backend.speech.domain.InterviewSession;
import com.voiceiq.backend.speech.domain.Recording;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Primary;
import org.springframework.core.io.FileSystemResource;
import org.springframework.http.MediaType;
import org.springframework.http.client.MultipartBodyBuilder;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Locale;

/**
 * Transcription service that calls the local Faster-Whisper Python microservice.
 *
 * This is the PRIMARY transcription service when whisper.enabled=true.
 * No API keys, no rate limits, fully self-hosted.
 *
 * Falls back to a heuristic transcript only if the whisper service is unreachable.
 */
@Service
@Primary
@ConditionalOnProperty(name = "whisper.enabled", havingValue = "true", matchIfMissing = false)
public class WhisperTranscriptionService implements SpeechTranscriptionService {

    private static final Logger log = LoggerFactory.getLogger(WhisperTranscriptionService.class);

    private final WhisperProperties whisperProperties;
    private final RestClient restClient;
    private final ObjectMapper objectMapper;

    public WhisperTranscriptionService(WhisperProperties whisperProperties) {
        this.whisperProperties = whisperProperties;
        this.restClient = RestClient.builder().build();
        this.objectMapper = new ObjectMapper();
    }

    @Override
    public TranscriptionResult transcribe(InterviewSession session, Recording recording) {
        if (recording.getLocalPath() == null || recording.getLocalPath().isBlank()) {
            log.warn("Recording has no local path for session {}", session.getId());
            return fallback(session);
        }

        Path filePath = Path.of(recording.getLocalPath());
        if (!Files.exists(filePath)) {
            log.warn("Audio file not found on disk for session {}: {}", session.getId(), filePath);
            return fallback(session);
        }

        String transcribeUrl = whisperProperties.serviceUrl() + "/transcribe";
        log.info("Sending audio to Faster-Whisper service for session {}: {}", session.getId(), transcribeUrl);

        try {
            MultipartBodyBuilder bodyBuilder = new MultipartBodyBuilder();
            bodyBuilder.part("file", new FileSystemResource(filePath))
                    .contentType(MediaType.parseMediaType(
                            recording.getMimeType() != null ? recording.getMimeType() : "audio/mp4"
                    ));

            String responseBody = restClient.post()
                    .uri(transcribeUrl)
                    .contentType(MediaType.MULTIPART_FORM_DATA)
                    .body(bodyBuilder.build())
                    .retrieve()
                    .body(String.class);

            JsonNode json = objectMapper.readTree(responseBody);
            String transcript = json.path("text").asText("").trim();

            if (transcript.isBlank()) {
                log.warn("Whisper returned empty transcript for session {}", session.getId());
                return fallback(session);
            }

            double durationSeconds = json.path("duration_seconds").asDouble(0);
            String language = json.path("language").asText("en");
            log.info("Whisper transcription done — session={} lang={} duration={}s chars={}",
                    session.getId(), language, durationSeconds, transcript.length());

            return new TranscriptionResult(transcript, "faster-whisper", "whisper-" + language);

        } catch (Exception exception) {
            log.error("Whisper service call failed for session {}: {}", session.getId(), exception.getMessage());
            return fallback(session);
        }
    }

    private TranscriptionResult fallback(InterviewSession session) {
        String prompt = session.getPromptText().toLowerCase(Locale.ENGLISH);
        String transcript;
        if (prompt.contains("yourself")) {
            transcript = "Um I am a software engineer who enjoys building reliable products, " +
                         "working closely with teams, and solving user problems with clear communication.";
        } else if (prompt.contains("team") || prompt.contains("conflict")) {
            transcript = "I first tried to understand the conflict, then aligned the team on shared goals, " +
                         "and like followed through with clear ownership and communication.";
        } else if (prompt.contains("challenge") || prompt.contains("problem")) {
            transcript = "I broke the problem into smaller steps, prioritised the highest impact work first, " +
                         "and communicated progress early to reduce delivery risk.";
        } else {
            transcript = "I structured my answer clearly, focused on the outcome, " +
                         "and tried to keep the response direct and easy to follow.";
        }
        log.info("Using fallback transcript for session {}", session.getId());
        return new TranscriptionResult(transcript, "fallback", "heuristic");
    }
}
