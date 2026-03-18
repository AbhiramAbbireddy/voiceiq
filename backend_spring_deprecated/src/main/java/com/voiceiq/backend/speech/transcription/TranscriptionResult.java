package com.voiceiq.backend.speech.transcription;

public record TranscriptionResult(
        String transcriptText,
        String provider,
        String model
) {
}
