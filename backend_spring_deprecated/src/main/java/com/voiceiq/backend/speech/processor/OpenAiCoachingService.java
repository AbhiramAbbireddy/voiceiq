package com.voiceiq.backend.speech.processor;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.voiceiq.backend.config.OpenAiProperties;
import com.voiceiq.backend.speech.domain.InterviewSession;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
public class OpenAiCoachingService implements AiCoachingService {

    private static final Logger log = LoggerFactory.getLogger(OpenAiCoachingService.class);

    private final OpenAiProperties openAiProperties;
    private final RestClient restClient;
    private final ObjectMapper objectMapper;

    public OpenAiCoachingService(OpenAiProperties openAiProperties) {
        this.openAiProperties = openAiProperties;
        this.objectMapper = new ObjectMapper();
        this.restClient = RestClient.builder().build();
    }

    @Override
    public AiCoachingResult generateCoaching(InterviewSession session, String transcriptText, SpeechSignalSnapshot signals) {
        AiCoachingResult fallback = fallback(session, transcriptText, signals);
        if (!openAiProperties.enabled() || openAiProperties.apiKey() == null || openAiProperties.apiKey().isBlank()) {
            return fallback;
        }

        try {
            JsonNode response = restClient.post()
                    .uri(openAiProperties.baseUrl() + "/responses")
                    .header(HttpHeaders.AUTHORIZATION, "Bearer " + openAiProperties.apiKey())
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(buildRequestBody(session, transcriptText, signals))
                    .retrieve()
                    .body(JsonNode.class);

            String outputText = extractOutputText(response);
            if (outputText == null || outputText.isBlank()) {
                log.warn("OpenAI coaching response did not contain output text for session {}", session.getId());
                return fallback;
            }

            JsonNode coachingJson = objectMapper.readTree(outputText);
            return new AiCoachingResult(
                    readText(coachingJson, "summary", fallback.summary()),
                    readList(coachingJson, "strengths", fallback.strengths()),
                    readList(coachingJson, "weaknesses", fallback.weaknesses()),
                    readList(coachingJson, "suggestions", fallback.suggestions()),
                    readText(coachingJson, "better_answer", transcriptText)
            );
        } catch (Exception exception) {
            log.warn("OpenAI coaching failed for session {}: {}", session.getId(), exception.getMessage());
            return fallback;
        }
    }

    private Map<String, Object> buildRequestBody(InterviewSession session, String transcriptText, SpeechSignalSnapshot signals) {
        Map<String, Object> schema = new LinkedHashMap<>();
        schema.put("type", "object");
        schema.put("additionalProperties", false);
        schema.put("properties", Map.of(
                "summary", Map.of("type", "string"),
                "strengths", Map.of(
                        "type", "array",
                        "items", Map.of("type", "string"),
                        "minItems", 2,
                        "maxItems", 3
                ),
                "weaknesses", Map.of(
                        "type", "array",
                        "items", Map.of("type", "string"),
                        "minItems", 2,
                        "maxItems", 3
                ),
                "suggestions", Map.of(
                        "type", "array",
                        "items", Map.of("type", "string"),
                        "minItems", 3,
                        "maxItems", 4
                ),
                "better_answer", Map.of("type", "string")
        ));
        schema.put("required", List.of("summary", "strengths", "weaknesses", "suggestions", "better_answer"));

        String systemPrompt = """
                You are VoiceIQ, an interview communication coach.
                Use the transcript and deterministic metrics to produce personalized coaching.
                Never invent metrics that are not provided.
                Make feedback specific, practical, and encouraging.
                Focus on communication quality for interviews.
                Return valid JSON only.
                """;

        String userPrompt = """
                Target role: %s
                Session type: %s
                Interview prompt: %s

                Transcript:
                %s

                Deterministic metrics:
                - words_per_minute: %d
                - filler_count: %d
                - filler_breakdown: %s
                - average_words_per_sentence: %d
                - hesitation_phrases: %s
                - pace_score: %d
                - clarity_score: %d
                - confidence_score: %d
                - filler_score: %d
                - overall_score: %d

                Produce:
                1. summary: 2 concise sentences
                2. strengths: 2-3 bullet-style strings grounded in the transcript
                3. weaknesses: 2-3 bullet-style strings grounded in the transcript
                4. suggestions: 3-4 actionable coaching tips using the actual metrics
                5. better_answer: rewrite the answer in a cleaner, more confident interview style while preserving the user's meaning
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
                signals.overallScore()
        );

        return Map.of(
                "model", openAiProperties.feedbackModel(),
                "input", List.of(
                        Map.of(
                                "role", "system",
                                "content", List.of(Map.of("type", "input_text", "text", systemPrompt))
                        ),
                        Map.of(
                                "role", "user",
                                "content", List.of(Map.of("type", "input_text", "text", userPrompt))
                        )
                ),
                "text", Map.of(
                        "format", Map.of(
                                "type", "json_schema",
                                "name", "voiceiq_feedback",
                                "strict", true,
                                "schema", schema
                        )
                ),
                "max_output_tokens", 900
        );
    }

    private String extractOutputText(JsonNode response) {
        String outputText = response.path("output_text").asText("");
        if (!outputText.isBlank()) {
            return outputText;
        }

        JsonNode output = response.path("output");
        if (output.isArray()) {
            for (JsonNode item : output) {
                JsonNode content = item.path("content");
                if (content.isArray()) {
                    for (JsonNode part : content) {
                        String text = part.path("text").asText("");
                        if (!text.isBlank()) {
                            return text;
                        }
                    }
                }
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

    private AiCoachingResult fallback(InterviewSession session, String transcriptText, SpeechSignalSnapshot signals) {
        List<String> strengths = new ArrayList<>();
        List<String> weaknesses = new ArrayList<>();
        List<String> suggestions = new ArrayList<>();

        if (signals.clarityScore() >= 78) {
            strengths.add("Your answer is reasonably clear and easy to follow.");
        }
        if (signals.fillerCount() <= 1) {
            strengths.add("You kept filler words under control, which helps your delivery sound more polished.");
        }
        if (signals.confidenceScore() >= 78) {
            strengths.add("Your wording is fairly direct, which supports a confident tone.");
        }

        if (signals.wordsPerMinute() < 120) {
            weaknesses.add("Your pace is around " + signals.wordsPerMinute() + " words per minute, which is a bit slow for an interview answer.");
            suggestions.add("Increase your pace slightly toward 130 to 160 wpm so your answer feels more confident and energetic.");
        } else if (signals.wordsPerMinute() > 160) {
            weaknesses.add("Your pace is a little fast, which can make the answer harder to absorb.");
            suggestions.add("Slow down slightly and leave a short pause after each key point.");
        }

        if (signals.fillerCount() > 0) {
            weaknesses.add("Filler words showed up in the response: " + String.join(", ", signals.fillerBreakdown()) + ".");
            suggestions.add("Replace those filler moments with a one-second silent pause so your delivery feels cleaner.");
        }

        if (!signals.hesitationPhrases().isEmpty()) {
            weaknesses.add("The transcript includes hesitation phrases such as " + String.join(", ", signals.hesitationPhrases()) + ".");
            suggestions.add("Use more direct phrasing and reduce softeners like \"I think\" when you already know your point.");
        }

        if (signals.averageWordsPerSentence() > 22) {
            weaknesses.add("Some sentences are long, which can weaken clarity under interview pressure.");
            suggestions.add("Break answers into shorter chunks using a simple point, example, result structure.");
        } else {
            strengths.add("Your sentence length is manageable, which supports good structure.");
        }

        while (strengths.size() < 2) {
            strengths.add("Your answer has a solid base and can become much stronger with a few delivery refinements.");
        }
        while (weaknesses.size() < 2) {
            weaknesses.add("The main opportunity is to make the answer sound more purposeful and interview-ready.");
        }
        while (suggestions.size() < 3) {
            suggestions.add("End each main sentence with a clear conclusion so your answer sounds more decisive.");
        }

        String summary = "This response has a solid foundation, but the biggest gains will come from tightening delivery around pace, clarity, and confidence. "
                + "The metrics suggest where to focus, and the next version should sound more polished and interview-ready.";

        String betterAnswer = rewriteAnswer(session, transcriptText);

        return new AiCoachingResult(summary, strengths.subList(0, Math.min(3, strengths.size())), weaknesses.subList(0, Math.min(3, weaknesses.size())), suggestions.subList(0, Math.min(4, suggestions.size())), betterAnswer);
    }

    private String rewriteAnswer(InterviewSession session, String transcriptText) {
        if (session.getPromptText().toLowerCase().contains("yourself")) {
            return "I am a software engineer who enjoys building reliable products, collaborating closely with teams, and solving user problems with clear communication. My background has helped me work across both technical execution and product impact, and I am especially motivated by building systems that improve real user experiences.";
        }
        return transcriptText;
    }
}
