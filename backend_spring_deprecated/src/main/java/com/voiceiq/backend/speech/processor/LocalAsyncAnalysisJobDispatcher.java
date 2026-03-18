package com.voiceiq.backend.speech.processor;

import com.voiceiq.backend.speech.domain.SessionStatus;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
@ConditionalOnProperty(prefix = "voiceiq.analysis", name = "dispatcher", havingValue = "local-async")
public class LocalAsyncAnalysisJobDispatcher implements AnalysisJobDispatcher {

    private static final Logger log = LoggerFactory.getLogger(LocalAsyncAnalysisJobDispatcher.class);

    private final AnalysisOrchestrationService analysisOrchestrationService;
    private final AnalysisStatusService analysisStatusService;

    public LocalAsyncAnalysisJobDispatcher(
            AnalysisOrchestrationService analysisOrchestrationService,
            AnalysisStatusService analysisStatusService
    ) {
        this.analysisOrchestrationService = analysisOrchestrationService;
        this.analysisStatusService = analysisStatusService;
    }

    @Override
    @Async("analysisTaskExecutor")
    public void dispatch(UUID sessionId) {
        log.info("Async analysis job started for session {}", sessionId);
        try {
            analysisOrchestrationService.processSession(sessionId);
            log.info("Async analysis job completed for session {}", sessionId);
        } catch (Exception exception) {
            log.error("Async analysis job failed for session {}", sessionId, exception);
            analysisStatusService.updateStatus(sessionId, SessionStatus.FAILED);
        }
    }
}
