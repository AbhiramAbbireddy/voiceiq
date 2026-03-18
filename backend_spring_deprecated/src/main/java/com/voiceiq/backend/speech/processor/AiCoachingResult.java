package com.voiceiq.backend.speech.processor;

import java.util.List;

public record AiCoachingResult(
        String summary,
        List<String> strengths,
        List<String> weaknesses,
        List<String> suggestions,
        String betterAnswer
) {
}
