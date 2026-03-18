package com.voiceiq.backend.speech.processor;

import com.voiceiq.backend.common.exception.NotFoundException;
import com.voiceiq.backend.speech.domain.InterviewSession;
import com.voiceiq.backend.speech.domain.SessionStatus;
import com.voiceiq.backend.speech.repository.InterviewSessionRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
public class AnalysisStatusService {

    private final InterviewSessionRepository sessionRepository;

    public AnalysisStatusService(InterviewSessionRepository sessionRepository) {
        this.sessionRepository = sessionRepository;
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void updateStatus(UUID sessionId, SessionStatus status) {
        InterviewSession session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new NotFoundException("Session not found"));
        session.setStatus(status);
        sessionRepository.save(session);
    }
}
