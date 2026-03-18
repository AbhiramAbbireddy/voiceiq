package com.voiceiq.backend.speech.processor;

public record TranscriptHighlight(
        String type,
        String value,
        int startIndex,
        int endIndex,
        String message
) {
}
