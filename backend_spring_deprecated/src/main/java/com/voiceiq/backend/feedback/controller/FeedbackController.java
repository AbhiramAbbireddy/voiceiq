package com.voiceiq.backend.feedback.controller;

import com.voiceiq.backend.common.api.ApiResponse;
import com.voiceiq.backend.feedback.dto.FeedbackReportResponse;
import com.voiceiq.backend.feedback.service.FeedbackService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/feedback")
public class FeedbackController {

    private final FeedbackService feedbackService;

    public FeedbackController(FeedbackService feedbackService) {
        this.feedbackService = feedbackService;
    }

    @GetMapping("/reports/{sessionId}")
    public ApiResponse<FeedbackReportResponse> getReport(@PathVariable UUID sessionId) {
        return ApiResponse.success(feedbackService.getReportForSession(sessionId), "Feedback report fetched successfully");
    }
}
