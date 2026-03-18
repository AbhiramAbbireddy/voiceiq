package com.voiceiq.backend.speech.processor;

import java.util.UUID;

public record AnalysisJobMessage(
        UUID sessionId
) {
}
