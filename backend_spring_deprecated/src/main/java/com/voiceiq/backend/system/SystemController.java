package com.voiceiq.backend.system;

import com.voiceiq.backend.common.api.ApiResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/system")
public class SystemController {

    @GetMapping("/info")
    public ApiResponse<Map<String, Object>> info() {
        return ApiResponse.success(
                Map.of(
                        "service", "voiceiq-backend",
                        "status", "UP",
                        "modules", new String[]{"auth", "speech", "feedback", "progress"}
                ),
                "VoiceIQ backend core is ready"
        );
    }
}
