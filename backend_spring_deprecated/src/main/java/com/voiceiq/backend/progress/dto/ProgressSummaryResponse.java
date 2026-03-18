package com.voiceiq.backend.progress.dto;

import java.util.List;
import java.util.UUID;

public record ProgressSummaryResponse(
        UUID userId,
        int totalSessions,
        int averageScore,
        int bestScore,
        int latestImprovementDelta,
        List<Integer> recentScores
) {
}
