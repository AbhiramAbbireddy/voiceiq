package com.voiceiq.backend.speech.processor;

import com.voiceiq.backend.speech.domain.InterviewSession;
import com.voiceiq.backend.speech.domain.Recording;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Service
public class SpeechAnalysisProcessor {

    private static final Pattern WORD_PATTERN = Pattern.compile("[A-Za-z']+");
    private static final Set<String> FILLER_WORDS = Set.of("um", "uh", "like", "actually", "basically");
    private static final List<String> FILLER_PHRASES = List.of("you know");
    private static final List<String> HESITATION_PHRASES = List.of("i think", "maybe", "kind of", "sort of", "i guess");

    private final AiCoachingService aiCoachingService;

    public SpeechAnalysisProcessor(AiCoachingService aiCoachingService) {
        this.aiCoachingService = aiCoachingService;
    }

    public SpeechAnalysisResult analyze(InterviewSession session, Recording recording, String transcriptText) {
        SpeechSignalSnapshot signals = extractSignals(recording, transcriptText);
        AiCoachingResult coaching = aiCoachingService.generateCoaching(session, transcriptText, signals);
        List<TranscriptHighlight> transcriptHighlights = buildTranscriptHighlights(transcriptText);

        return new SpeechAnalysisResult(
                transcriptText,
                signals.fillerCount(),
                signals.wordsPerMinute(),
                signals.overallScore(),
                signals.paceScore(),
                signals.clarityScore(),
                signals.confidenceScore(),
                signals.fillerScore(),
                coaching.summary(),
                coaching.strengths(),
                coaching.weaknesses(),
                coaching.suggestions(),
                coaching.betterAnswer(),
                signals.fillerBreakdown(),
                signals.hesitationPhrases(),
                transcriptHighlights
        );
    }

    private SpeechSignalSnapshot extractSignals(Recording recording, String transcriptText) {
        int durationSeconds = Math.max(recording.getDurationSeconds(), 45);
        int totalWords = countWords(transcriptText);
        int wordsPerMinute = Math.max(80, (int) Math.round((totalWords * 60.0) / durationSeconds));

        Map<String, Integer> fillerCounts = countFillerWords(transcriptText);
        int fillerCount = fillerCounts.values().stream().mapToInt(Integer::intValue).sum();
        List<String> fillerBreakdown = fillerCounts.entrySet().stream()
                .sorted(Map.Entry.<String, Integer>comparingByValue(Comparator.reverseOrder()))
                .map(entry -> entry.getKey() + ": " + entry.getValue())
                .toList();

        int sentenceCount = estimateSentenceCount(transcriptText);
        int averageWordsPerSentence = Math.max(1, totalWords / sentenceCount);
        List<String> hesitationPhrases = detectHesitationPhrases(transcriptText);

        int paceScore = scorePace(wordsPerMinute);
        int clarityScore = scoreClarity(totalWords, fillerCount, averageWordsPerSentence);
        int confidenceScore = scoreConfidence(hesitationPhrases, fillerCount);
        int fillerScore = Math.max(40, 86 - (fillerCount * 4));
        int overallScore = (paceScore + clarityScore + confidenceScore + fillerScore) / 4;

        return new SpeechSignalSnapshot(
                wordsPerMinute,
                fillerCount,
                fillerBreakdown,
                averageWordsPerSentence,
                hesitationPhrases,
                paceScore,
                clarityScore,
                confidenceScore,
                fillerScore,
                overallScore
        );
    }

    private int scorePace(int wordsPerMinute) {
        if (wordsPerMinute >= 130 && wordsPerMinute <= 160) {
            return 84;
        }
        if (wordsPerMinute >= 120 && wordsPerMinute <= 170) {
            return 72;
        }
        return 58;
    }

    private int scoreClarity(int totalWords, int fillerCount, int averageWordsPerSentence) {
        int fillerPenalty = fillerCount * 2;
        int longPhrasePenalty = Math.max(0, averageWordsPerSentence - 18);
        return Math.max(45, Math.min(92, 84 - fillerPenalty - longPhrasePenalty));
    }

    private int scoreConfidence(List<String> hesitationPhrases, int fillerCount) {
        int uncertaintyPenalty = hesitationPhrases.size() * 5;
        return Math.max(48, Math.min(90, 84 - (fillerCount * 2) - uncertaintyPenalty));
    }

    private int countWords(String transcriptText) {
        Matcher matcher = WORD_PATTERN.matcher(transcriptText);
        int count = 0;
        while (matcher.find()) {
            count++;
        }
        return Math.max(1, count);
    }

    private Map<String, Integer> countFillerWords(String transcriptText) {
        String lowerCaseTranscript = transcriptText.toLowerCase(Locale.ENGLISH);
        Matcher matcher = WORD_PATTERN.matcher(lowerCaseTranscript);
        Map<String, Integer> counts = new LinkedHashMap<>();
        while (matcher.find()) {
            String currentWord = matcher.group();
            if (FILLER_WORDS.contains(currentWord)) {
                counts.merge(currentWord, 1, Integer::sum);
            }
        }
        for (String phrase : FILLER_PHRASES) {
            int occurrences = countPhraseOccurrences(lowerCaseTranscript, phrase);
            if (occurrences > 0) {
                counts.merge(phrase, occurrences, Integer::sum);
            }
        }
        return counts;
    }

    private List<String> detectHesitationPhrases(String transcriptText) {
        String lowerCaseTranscript = transcriptText.toLowerCase(Locale.ENGLISH);
        List<String> detected = new ArrayList<>();
        for (String phrase : HESITATION_PHRASES) {
            if (lowerCaseTranscript.contains(phrase)) {
                detected.add(phrase);
            }
        }
        return detected;
    }

    private int estimateSentenceCount(String transcriptText) {
        int punctuationSentenceCount = 0;
        for (char current : transcriptText.toCharArray()) {
            if (current == '.' || current == '!' || current == '?') {
                punctuationSentenceCount++;
            }
        }
        return Math.max(1, punctuationSentenceCount);
    }

    private int countPhraseOccurrences(String transcriptText, String phrase) {
        int count = 0;
        int index = 0;
        while ((index = transcriptText.indexOf(phrase, index)) != -1) {
            count++;
            index += phrase.length();
        }
        return count;
    }

    private List<TranscriptHighlight> buildTranscriptHighlights(String transcriptText) {
        List<TranscriptHighlight> highlights = new ArrayList<>();
        String lowerCaseTranscript = transcriptText.toLowerCase(Locale.ENGLISH);

        Matcher wordMatcher = WORD_PATTERN.matcher(lowerCaseTranscript);
        while (wordMatcher.find()) {
            String word = wordMatcher.group();
            if (FILLER_WORDS.contains(word)) {
                highlights.add(new TranscriptHighlight(
                        "FILLER_WORD",
                        transcriptText.substring(wordMatcher.start(), wordMatcher.end()),
                        wordMatcher.start(),
                        wordMatcher.end(),
                        "Replace this filler word with a brief silent pause."
                ));
            }
        }

        for (String phrase : FILLER_PHRASES) {
            addPhraseHighlights(highlights, transcriptText, lowerCaseTranscript, phrase, "FILLER_PHRASE", "This phrase can weaken clarity. Try pausing instead.");
        }

        for (String phrase : HESITATION_PHRASES) {
            addPhraseHighlights(highlights, transcriptText, lowerCaseTranscript, phrase, "HESITATION_PHRASE", "This phrase sounds tentative. Use a more direct statement.");
        }

        highlights.sort(Comparator.comparingInt(TranscriptHighlight::startIndex));
        return highlights;
    }

    private void addPhraseHighlights(
            List<TranscriptHighlight> highlights,
            String transcriptText,
            String lowerCaseTranscript,
            String phrase,
            String type,
            String message
    ) {
        int index = 0;
        while ((index = lowerCaseTranscript.indexOf(phrase, index)) != -1) {
            int endIndex = index + phrase.length();
            highlights.add(new TranscriptHighlight(
                    type,
                    transcriptText.substring(index, endIndex),
                    index,
                    endIndex,
                    message
            ));
            index = endIndex;
        }
    }
}
