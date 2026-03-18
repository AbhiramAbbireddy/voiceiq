package com.voiceiq.backend.speech.transcription;

import com.voiceiq.backend.common.exception.BadRequestException;
import com.voiceiq.backend.config.OpenAiProperties;
import com.voiceiq.backend.speech.domain.InterviewSession;
import com.voiceiq.backend.speech.domain.Recording;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.io.FileSystemResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestClient;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Locale;

@Service
public class OpenAiSpeechTranscriptionService implements SpeechTranscriptionService {

    private static final Logger log = LoggerFactory.getLogger(OpenAiSpeechTranscriptionService.class);

    private final OpenAiProperties openAiProperties;
    private final RestClient restClient;

    public OpenAiSpeechTranscriptionService(OpenAiProperties openAiProperties) {
        this.openAiProperties = openAiProperties;
        this.restClient = RestClient.builder().build();
    }

    @Override
    public TranscriptionResult transcribe(InterviewSession session, Recording recording) {
        if (!openAiProperties.enabled() || openAiProperties.apiKey() == null || openAiProperties.apiKey().isBlank()) {
            log.info("OpenAI transcription disabled or API key missing, using fallback transcript for session {}", session.getId());
            return fallback(session);
        }

        if (recording.getLocalPath() == null || recording.getLocalPath().isBlank()) {
            throw new BadRequestException("Recording file path is missing");
        }

        Path filePath = Path.of(recording.getLocalPath());
        if (!Files.exists(filePath)) {
            throw new BadRequestException("Recording file does not exist on disk");
        }

        MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
        body.add("file", new FileSystemResource(filePath));
        body.add("model", openAiProperties.transcriptionModel());
        body.add("response_format", "json");
        body.add("language", "en");
        body.add("prompt", "Transcribe this interview practice response accurately. Preserve filler words like um, uh, and like.");

        try {
            OpenAiTranscriptionResponse response = restClient.post()
                    .uri(openAiProperties.whisperUrl())
                    .header(HttpHeaders.AUTHORIZATION, "Bearer " + openAiProperties.apiKey())
                    .contentType(MediaType.MULTIPART_FORM_DATA)
                    .body(body)
                    .retrieve()
                    .body(OpenAiTranscriptionResponse.class);

            if (response == null || response.text() == null || response.text().isBlank()) {
                throw new BadRequestException("OpenAI returned an empty transcript");
            }

            return new TranscriptionResult(
                    response.text().trim(),
                    "openai",
                    openAiProperties.transcriptionModel()
            );
        } catch (RuntimeException exception) {
            log.warn("OpenAI transcription failed for session {}: {}", session.getId(), exception.getMessage());
            return fallback(session);
        }
    }

    private TranscriptionResult fallback(InterviewSession session) {
        String normalizedPrompt = session.getPromptText().toLowerCase(Locale.ENGLISH);
        String transcript;
        if (normalizedPrompt.contains("yourself")) {
            transcript = "Um I am a software engineer who enjoys building reliable products, working closely with teams, and solving user problems with clear communication.";
        } else if (normalizedPrompt.contains("team")) {
            transcript = "I first tried to understand the conflict, then aligned the team on shared goals, and like followed through with clear ownership and communication.";
        } else if (normalizedPrompt.contains("challenge") || normalizedPrompt.contains("problem")) {
            transcript = "I broke the problem into smaller steps, prioritised the highest impact work first, and communicated progress early to reduce delivery risk.";
        } else {
            transcript = "I structured my answer clearly, focused on the outcome, and tried to keep the response direct and easy to follow.";
        }

        return new TranscriptionResult(transcript, "fallback", "heuristic");
    }
}
