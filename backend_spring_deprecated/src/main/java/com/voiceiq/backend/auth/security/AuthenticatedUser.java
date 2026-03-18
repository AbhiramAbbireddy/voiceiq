package com.voiceiq.backend.auth.security;

import java.util.UUID;

public record AuthenticatedUser(
        UUID userId,
        String email,
        String fullName,
        String targetRole
) {
}
