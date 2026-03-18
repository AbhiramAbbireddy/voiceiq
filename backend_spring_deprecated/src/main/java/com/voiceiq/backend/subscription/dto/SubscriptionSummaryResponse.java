package com.voiceiq.backend.subscription.dto;

import com.voiceiq.backend.auth.domain.PlanType;
import com.voiceiq.backend.subscription.domain.SubscriptionProvider;
import com.voiceiq.backend.subscription.domain.SubscriptionStatus;

import java.time.LocalDateTime;
import java.util.UUID;

public record SubscriptionSummaryResponse(
        UUID userId,
        PlanType plan,
        SubscriptionStatus status,
        SubscriptionProvider provider,
        boolean developerAccount,
        LocalDateTime currentPeriodStart,
        LocalDateTime currentPeriodEnd,
        int sessionsUsed,
        int sessionLimit,
        int sessionsRemaining,
        int processedSecondsUsed,
        int processedSecondsLimit,
        int processedSecondsRemaining
) {
}
