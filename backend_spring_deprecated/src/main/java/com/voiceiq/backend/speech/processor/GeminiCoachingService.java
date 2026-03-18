package com.voiceiq.backend.speech.processor;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.voiceiq.backend.config.GeminiProperties;
import com.voiceiq.backend.speech.domain.InterviewSession;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Primary;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Service
@Primary
@ConditionalOnProperty(name = "gemini.enabled", havingValue = "true")
public class GeminiCoachingService implements AiCoachingService {

    private static final Logger log = LoggerFactory.getLogger(GeminiCoachingService.class);

    private final GeminiProperties geminiProperties;
    private final RestClient restClient;
    private final ObjectMapper objectMapper;

    public GeminiCoachingService(GeminiProperties geminiProperties) {
        this.geminiProperties = geminiProperties;
        this.restClient = RestClient.builder().build();
        this.objectMapper = new ObjectMapper();
    }

    @Override
    public AiCoachingResult generateCoaching(InterviewSession session, String transcriptText,
            SpeechSignalSnapshot signals) {
        AiCoachingResult fallbackResult = buildFallback(session, transcriptText, signals);

        if (geminiProperties.apiKey() == null || geminiProperties.apiKey().isBlank()) {
            return fallbackResult;
        }

        try {
            String url = geminiProperties.baseUrl() + "/models/" + geminiProperties.model()
                    + ":generateContent?key=" + geminiProperties.apiKey();

            String prompt = """
                    You are VoiceIQ, an interview communication coach.
                    Analyze the following interview response and provide personalized coaching.
                    Be specific, practical, and encouraging. Focus on communication quality.

                    Target role: %s
                    Session type: %s
                    Interview prompt: %s

                    Transcript:
                    %s

                    Metrics:
                    - Words per minute: %d
                    - Filler count: %d
                    - Filler breakdown: %s
                    - Average words per sentence: %d
                    - Hesitation phrases: %s
                    - Pace score: %d/100
                    - Clarity score: %d/100
                    - Confidence score: %d/100
                    - Filler score: %d/100
                    - Overall score: %d/100

                    Respond with ONLY valid JSON (no markdown, no code fences) in this exact format:
                    {
                      "summary": "2 concise sentences about overall performance",
                      "strengths": ["strength 1", "strength 2"],
                      "weaknesses": ["weakness 1", "weakness 2"],
                      "suggestions": ["suggestion 1", "suggestion 2", "suggestion 3"],
                      "better_answer": "A rewritten, cleaner, more confident version of the answer"
                    }
                    """.formatted(
                    session.getUser().getTargetRole(),
                    session.getType(),
                    session.getPromptText(),
                    transcriptText,
                    signals.wordsPerMinute(),
                    signals.fillerCount(),
                    signals.fillerBreakdown(),
                    signals.averageWordsPerSentence(),
                    signals.hesitationPhrases(),
                    signals.paceScore(),
                    signals.clarityScore(),
                    signals.confidenceScore(),
                    signals.fillerScore(),
                    signals.overallScore());

            Map<String, Object> requestBody = Map.of(
                    "contents", List.of(Map.of(
                            "parts", List.of(Map.of("text", prompt)))),
                    "generationConfig", Map.of(
                            "temperature", 0.7,
                            "maxOutputTokens", 1200,
                            "responseMimeType", "application/json"));

            String responseJson = restClient.post()
                    .uri(url)
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(requestBody)
                    .retrieve()
                    .body(String.class);

            JsonNode response = objectMapper.readTree(responseJson);
            String outputText = extractText(response);

            if (outputText == null || outputText.isBlank()) {
                log.warn("Gemini coaching returned empty output for session {}", session.getId());
                return fallbackResult;
            }

            JsonNode coaching = objectMapper.readTree(outputText);
            log.info("Gemini coaching succeeded for session {}", session.getId());

            return new AiCoachingResult(
                    readText(coaching, "summary", fallbackResult.summary()),
                    readList(coaching, "strengths", fallbackResult.strengths()),
                    readList(coaching, "weaknesses", fallbackResult.weaknesses()),
                    readList(coaching, "suggestions", fallbackResult.suggestions()),
                    readText(coaching, "better_answer", transcriptText));

        } catch (Exception exception) {
            log.warn("Gemini coaching failed for session {}: {}", session.getId(), exception.getMessage());
            return fallbackResult;
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

    private String readText(JsonNode root, String field, String fallback) {
        String value = root.path(field).asText("");
        return value.isBlank() ? fallback : value;
    }

    private List<String> readList(JsonNode root, String field, List<String> fallback) {
        List<String> values = new ArrayList<>();
        JsonNode node = root.path(field);
        if (node.isArray()) {
            for (JsonNode item : node) {
                String value = item.asText("");
                if (!value.isBlank()) {
                    values.add(value.trim());
                }
            }
        }
        return values.isEmpty() ? fallback : values;
    }

    private AiCoachingResult buildFallback(InterviewSession session, String transcriptText,
            SpeechSignalSnapshot signals) {
        List<String> strengths = new ArrayList<>();
        List<String> weaknesses = new ArrayList<>();
        List<String> suggestions = new ArrayList<>();

        if (signals.clarityScore() >= 78)
            strengths.add("Your answer is reasonably clear and easy to follow.");
        if (signals.fillerCount() <= 1)
            strengths.add("Good control of filler words.");
        if (signals.confidenceScore() >= 78)
            strengths.add("Your wording is fairly direct and confident.");

        if (signals.wordsPerMinute() < 120) {
            weaknesses.add("Pace is around " + signals.wordsPerMinute() + " wpm, a bit slow for interviews.");
            suggestions.add("Increase pace toward 130-160 wpm for better energy.");
        }
        if (signals.fillerCount() > 0) {
            weaknesses.add("Filler words detected: " + String.join(", ", signals.fillerBreakdown()) + ".");
            suggestions.add("Replace fillers with brief silent pauses.");
        }

        while (strengths.size() < 2)
            strengths.add("Your answer has a solid base for improvement.");
        while (weaknesses.size() < 2)
            weaknesses.add("Focus on making the answer sound more interview-ready.");
        while (suggestions.size() < 3)
            suggestions.add("End each point with a clear conclusion for decisiveness.");

        return new AiCoachingResult(
                "This response shows potential. Focus on the metrics to sharpen your delivery.",
                strengths.subList(0, Math.min(3, strengths.size())),
                weaknesses.subList(0, Math.min(3, weaknesses.size())),
                suggestions.subList(0, Math.min(4, suggestions.size())),
                transcriptText);
    }
}
