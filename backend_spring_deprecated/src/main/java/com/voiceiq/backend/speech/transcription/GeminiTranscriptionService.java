package com.voiceiq.backend.speech.transcription;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.voiceiq.backend.config.GeminiProperties;
import com.voiceiq.backend.speech.domain.InterviewSession;
import com.voiceiq.backend.speech.domain.Recording;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Base64;
import java.util.List;
import java.util.Map;

/**
 * Fallback transcription service that uses Gemini to transcribe audio.
 * Only activated when whisper is DISABLED and gemini is enabled.
 * 
 * When whisper.enabled=true, WhisperTranscriptionService takes priority
 * because it is @Primary and uses the local Faster-Whisper model (no API limits).
 */
@Service
@ConditionalOnProperty(name = "whisper.enabled", havingValue = "false")
public class GeminiTranscriptionService implements SpeechTranscriptionService {

    private static final Logger log = LoggerFactory.getLogger(GeminiTranscriptionService.class);

    private final GeminiProperties geminiProperties;
    private final RestClient restClient;
    private final ObjectMapper objectMapper;

    public GeminiTranscriptionService(GeminiProperties geminiProperties) {
        this.geminiProperties = geminiProperties;
        this.restClient = RestClient.builder().build();
        this.objectMapper = new ObjectMapper();
    }

    @Override
    public TranscriptionResult transcribe(InterviewSession session, Recording recording) {
        if (geminiProperties.apiKey() == null || geminiProperties.apiKey().isBlank()) {
            log.warn("Gemini API key is missing, using fallback transcript for session {}", session.getId());
            return fallback(session);
        }

        if (recording.getLocalPath() == null || recording.getLocalPath().isBlank()) {
            log.warn("Recording file path is missing for session {}", session.getId());
            return fallback(session);
        }

        Path filePath = Path.of(recording.getLocalPath());
        if (!Files.exists(filePath)) {
            log.warn("Recording file does not exist for session {}: {}", session.getId(), filePath);
            return fallback(session);
        }

        try {
            byte[] audioBytes = Files.readAllBytes(filePath);
            String base64Audio = Base64.getEncoder().encodeToString(audioBytes);
            String mimeType = recording.getMimeType() != null ? recording.getMimeType() : "audio/mp4";

            String url = geminiProperties.baseUrl() + "/models/" + geminiProperties.model()
                    + ":generateContent?key=" + geminiProperties.apiKey();

            Map<String, Object> requestBody = Map.of(
                    "contents", List.of(Map.of(
                            "parts", List.of(
                                    Map.of("text",
                                            "Transcribe this audio recording accurately. " +
                                                    "Preserve all filler words like um, uh, like, basically, actually, and you know. "
                                                    +
                                                    "Do NOT add any commentary, labels, or formatting. " +
                                                    "Return ONLY the raw transcript text, nothing else."),
                                    Map.of("inline_data", Map.of(
                                            "mime_type", mimeType,
                                            "data", base64Audio))))),
                    "generationConfig", Map.of(
                            "temperature", 0.1,
                            "maxOutputTokens", 2000));

            String responseJson = restClient.post()
                    .uri(url)
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(requestBody)
                    .retrieve()
                    .body(String.class);

            JsonNode response = objectMapper.readTree(responseJson);
            String transcript = extractText(response);

            if (transcript == null || transcript.isBlank()) {
                log.warn("Gemini returned empty transcript for session {}", session.getId());
                return fallback(session);
            }

            log.info("Gemini transcription succeeded for session {} ({} chars)", session.getId(), transcript.length());
            return new TranscriptionResult(transcript.trim(), "gemini", geminiProperties.model());

        } catch (IOException ioException) {
            log.error("Failed to read audio file for session {}", session.getId(), ioException);
            return fallback(session);
        } catch (Exception exception) {
            log.warn("Gemini transcription failed for session {}: {}", session.getId(), exception.getMessage());
            return fallback(session);
        }
    }

    private String extractText(JsonNode response) {
        JsonNode candidates = response.path("candidates");
        if (candidates.isArray() && !candidates.isEmpty()) {
            JsonNode parts = candidates.get(0).path("content").path("parts");
            if (parts.isArray() && !parts.isEmpty()) {
                return parts.get(0).path("text").asText("");
            }
        }
        return null;
    }

    private TranscriptionResult fallback(InterviewSession session) {
        String prompt = session.getPromptText().toLowerCase();
        String transcript;
        if (prompt.contains("yourself")) {
            transcript = "Um I am a software engineer who enjoys building reliable products, working closely with teams, and solving user problems with clear communication.";
        } else if (prompt.contains("team")) {
            transcript = "I first tried to understand the conflict, then aligned the team on shared goals, and like followed through with clear ownership and communication.";
        } else {
            transcript = "I structured my answer clearly, focused on the outcome, and tried to keep the response direct and easy to follow.";
        }
        return new TranscriptionResult(transcript, "fallback", "heuristic");
    }
}
