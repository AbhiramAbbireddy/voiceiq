class FeedbackReport {
  const FeedbackReport({
    required this.reportId,
    required this.sessionId,
    required this.overallScore,
    required this.paceScore,
    required this.clarityScore,
    required this.confidenceScore,
    required this.fillerScore,
    required this.transcriptText,
    required this.transcriptHighlights,
    required this.summary,
    required this.strengths,
    required this.weaknesses,
    required this.suggestions,
    required this.betterAnswer,
    required this.fillerBreakdown,
    required this.hesitationPhrases,
  });

  final String reportId;
  final String sessionId;
  final int overallScore;
  final int paceScore;
  final int clarityScore;
  final int confidenceScore;
  final int fillerScore;
  final String transcriptText;
  final List<TranscriptHighlight> transcriptHighlights;
  final String summary;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> suggestions;
  final String betterAnswer;
  final List<String> fillerBreakdown;
  final List<String> hesitationPhrases;

  factory FeedbackReport.fromJson(Map<String, dynamic> json) {
    return FeedbackReport(
      reportId: json['reportId'] as String,
      sessionId: json['sessionId'] as String,
      overallScore: json['overallScore'] as int? ?? 0,
      paceScore: json['paceScore'] as int? ?? 0,
      clarityScore: json['clarityScore'] as int? ?? 0,
      confidenceScore: json['confidenceScore'] as int? ?? 0,
      fillerScore: json['fillerScore'] as int? ?? 0,
      transcriptText: json['transcriptText'] as String? ?? '',
      transcriptHighlights:
          (json['transcriptHighlights'] as List<dynamic>? ?? const [])
              .whereType<Map>()
              .map((value) => TranscriptHighlight.fromJson(Map<String, dynamic>.from(value)))
              .toList(),
      summary: json['summary'] as String? ?? '',
      strengths: (json['strengths'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
      weaknesses: (json['weaknesses'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
      suggestions: (json['suggestions'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
      betterAnswer: json['betterAnswer'] as String? ?? '',
      fillerBreakdown: (json['fillerBreakdown'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
      hesitationPhrases:
          (json['hesitationPhrases'] as List<dynamic>? ?? const [])
              .map((value) => value.toString())
              .toList(),
    );
  }
}

class TranscriptHighlight {
  const TranscriptHighlight({
    required this.type,
    required this.value,
    required this.startIndex,
    required this.endIndex,
    required this.message,
  });

  final String type;
  final String value;
  final int startIndex;
  final int endIndex;
  final String message;

  factory TranscriptHighlight.fromJson(Map<String, dynamic> json) {
    return TranscriptHighlight(
      type: json['type'] as String? ?? 'FILLER_WORD',
      value: json['value'] as String? ?? '',
      startIndex: json['startIndex'] as int? ?? 0,
      endIndex: json['endIndex'] as int? ?? 0,
      message: json['message'] as String? ?? '',
    );
  }
}
