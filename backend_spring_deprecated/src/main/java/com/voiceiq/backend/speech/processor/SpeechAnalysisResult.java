package com.voiceiq.backend.speech.processor;

public record SpeechAnalysisResult(
        String transcriptText,
        int fillerCount,
        int wordsPerMinute,
        int overallScore,
        int paceScore,
        int clarityScore,
        int confidenceScore,
        int fillerScore,
        String summary,
        java.util.List<String> strengths,
        java.util.List<String> weaknesses,
        java.util.List<String> suggestions,
        String betterAnswer,
        java.util.List<String> fillerBreakdown,
        java.util.List<String> hesitationPhrases,
        java.util.List<TranscriptHighlight> transcriptHighlights
) {
}
