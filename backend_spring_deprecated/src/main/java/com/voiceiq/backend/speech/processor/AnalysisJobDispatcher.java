package com.voiceiq.backend.speech.processor;

import java.util.UUID;

public interface AnalysisJobDispatcher {
    void dispatch(UUID sessionId);
}
