package com.voiceiq.backend.feedback.dto;

public record TranscriptHighlightResponse(
        String type,
        String value,
        int startIndex,
        int endIndex,
        String message
) {
}
