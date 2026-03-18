package com.voiceiq.backend.speech.processor;

import com.voiceiq.backend.speech.domain.InterviewSession;

public interface AiCoachingService {
    AiCoachingResult generateCoaching(InterviewSession session, String transcriptText, SpeechSignalSnapshot signals);
}
