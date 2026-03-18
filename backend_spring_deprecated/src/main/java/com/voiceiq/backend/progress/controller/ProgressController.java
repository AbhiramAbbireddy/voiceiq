package com.voiceiq.backend.progress.controller;

import com.voiceiq.backend.common.api.ApiResponse;
import com.voiceiq.backend.progress.dto.ProgressSummaryResponse;
import com.voiceiq.backend.progress.service.ProgressService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/progress")
public class ProgressController {

    private final ProgressService progressService;

    public ProgressController(ProgressService progressService) {
        this.progressService = progressService;
    }

    @GetMapping("/summary/{userId}")
    public ApiResponse<ProgressSummaryResponse> getSummary(@PathVariable UUID userId) {
        return ApiResponse.success(progressService.getSummary(userId), "Progress summary fetched successfully");
    }
}
