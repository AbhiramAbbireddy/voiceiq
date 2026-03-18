package com.voiceiq.backend.speech.processor;

import java.util.List;

public record SpeechSignalSnapshot(
        int wordsPerMinute,
        int fillerCount,
        List<String> fillerBreakdown,
        int averageWordsPerSentence,
        List<String> hesitationPhrases,
        int paceScore,
        int clarityScore,
        int confidenceScore,
        int fillerScore,
        int overallScore
) {
}
