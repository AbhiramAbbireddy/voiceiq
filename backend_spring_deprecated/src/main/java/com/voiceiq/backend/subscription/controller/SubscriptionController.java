package com.voiceiq.backend.subscription.controller;

import com.voiceiq.backend.common.api.ApiResponse;
import com.voiceiq.backend.subscription.dto.SubscriptionSummaryResponse;
import com.voiceiq.backend.subscription.service.SubscriptionService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/subscription")
public class SubscriptionController {

    private final SubscriptionService subscriptionService;

    public SubscriptionController(SubscriptionService subscriptionService) {
        this.subscriptionService = subscriptionService;
    }

    @GetMapping("/me")
    public ApiResponse<SubscriptionSummaryResponse> getCurrentSubscription() {
        return ApiResponse.success(
                subscriptionService.getCurrentSummary(),
                "Subscription summary fetched successfully"
        );
    }
}
