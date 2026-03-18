package com.voiceiq.backend.feedback.dto;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public record FeedbackReportResponse(
        UUID reportId,
        UUID sessionId,
        int overallScore,
        int paceScore,
        int clarityScore,
        int confidenceScore,
        int fillerScore,
        String transcriptText,
        List<TranscriptHighlightResponse> transcriptHighlights,
        String summary,
        List<String> strengths,
        List<String> weaknesses,
        List<String> suggestions,
        String betterAnswer,
        List<String> fillerBreakdown,
        List<String> hesitationPhrases,
        LocalDateTime createdAt
) {
}
