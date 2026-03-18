package com.voiceiq.backend.progress.service;

import com.voiceiq.backend.auth.security.CurrentUserService;
import com.voiceiq.backend.common.exception.NotFoundException;
import com.voiceiq.backend.progress.dto.ProgressSummaryResponse;
import com.voiceiq.backend.progress.repository.ProgressScoreRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
public class ProgressService {

    private final ProgressScoreRepository progressScoreRepository;
    private final CurrentUserService currentUserService;

    public ProgressService(ProgressScoreRepository progressScoreRepository, CurrentUserService currentUserService) {
        this.progressScoreRepository = progressScoreRepository;
        this.currentUserService = currentUserService;
    }

    public ProgressSummaryResponse getSummary(UUID userId) {
        if (!currentUserService.requireCurrentUser().userId().equals(userId)) {
            throw new NotFoundException("User not found");
        }

        List<Integer> scores = progressScoreRepository.findTop30ByUser_IdOrderByCreatedAtDesc(userId)
                .stream()
                .map(progress -> progress.getOverallScore())
                .toList();

        int totalSessions = scores.size();
        int averageScore = totalSessions == 0 ? 0 : (int) scores.stream().mapToInt(Integer::intValue).average().orElse(0);
        int bestScore = scores.stream().mapToInt(Integer::intValue).max().orElse(0);
        int latestImprovement = progressScoreRepository.findTop30ByUser_IdOrderByCreatedAtDesc(userId)
                .stream()
                .findFirst()
                .map(progress -> progress.getImprovementDelta())
                .orElse(0);

        return new ProgressSummaryResponse(
                userId,
                totalSessions,
                averageScore,
                bestScore,
                latestImprovement,
                scores
        );
    }
}
