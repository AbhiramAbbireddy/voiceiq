package com.voiceiq.backend.speech.transcription;

import com.voiceiq.backend.speech.domain.InterviewSession;
import com.voiceiq.backend.speech.domain.Recording;

public interface SpeechTranscriptionService {
    TranscriptionResult transcribe(InterviewSession session, Recording recording);
}
