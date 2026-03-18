package com.voiceiq.backend.auth.dto;

import com.voiceiq.backend.auth.domain.PlanType;

import java.util.UUID;

public record AuthResponse(
        UUID userId,
        String fullName,
        String email,
        String targetRole,
        PlanType plan,
        String token
) {
}
