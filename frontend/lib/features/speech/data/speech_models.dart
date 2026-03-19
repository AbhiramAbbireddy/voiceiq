import '../../analysis/data/feedback_report.dart';

class VoiceSession {
  const VoiceSession({
    required this.sessionId,
    required this.status,
    required this.promptText,
  });

  final String sessionId;
  final String status;
  final String promptText;

  factory VoiceSession.fromJson(Map<String, dynamic> json) {
    return VoiceSession(
      sessionId: json['sessionId'] as String,
      status: json['status'] as String? ?? 'CREATED',
      promptText: json['promptText'] as String? ?? '',
    );
  }
}

class UploadPreparation {
  const UploadPreparation({
    required this.sessionId,
    required this.recordingId,
    required this.uploadType,
    required this.uploadUrl,
    required this.objectKey,
    required this.storageUrl,
    required this.requiredHeaders,
  });

  final String sessionId;
  final String recordingId;
  final String uploadType;
  final String uploadUrl;
  final String? objectKey;
  final String storageUrl;
  final Map<String, String> requiredHeaders;

  factory UploadPreparation.fromJson(Map<String, dynamic> json) {
    final rawHeaders = json['requiredHeaders'] as Map<String, dynamic>? ?? const {};
    return UploadPreparation(
      sessionId: json['sessionId'] as String,
      recordingId: json['recordingId'] as String,
      uploadType: json['uploadType'] as String? ?? 'BACKEND_MULTIPART',
      uploadUrl: json['uploadUrl'] as String,
      objectKey: json['objectKey'] as String?,
      storageUrl: json['storageUrl'] as String? ?? '',
      requiredHeaders: rawHeaders.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
  }
}

class RecordingUploadResult {
  const RecordingUploadResult({
    required this.sessionId,
    required this.status,
  });

  final String sessionId;
  final String status;

  factory RecordingUploadResult.fromJson(Map<String, dynamic> json) {
    return RecordingUploadResult(
      sessionId: json['sessionId'] as String,
      status: json['status'] as String? ?? 'UPLOADED',
    );
  }
}

class SessionStatusModel {
  const SessionStatusModel({
    required this.sessionId,
    required this.status,
    required this.reportReady,
    required this.transcriptReady,
    required this.message,
    this.fallbackReport,
  });

  final String sessionId;
  final String status;
  final bool reportReady;
  final bool transcriptReady;
  final String message;
  final FeedbackReport? fallbackReport;

  factory SessionStatusModel.fromJson(Map<String, dynamic> json) {
    final transcript = json['transcript'];
    final report = json['report'];
    return SessionStatusModel(
      sessionId: json['sessionId'] as String,
      status: json['status'] as String? ?? 'CREATED',
      reportReady: json['reportReady'] as bool? ?? false,
      transcriptReady: json['transcriptReady'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      fallbackReport: transcript is Map<String, dynamic> && report is Map<String, dynamic>
          ? _legacyFeedbackReportFromStatus(
              sessionId: json['sessionId'] as String,
              transcript: transcript,
              report: report,
            )
          : null,
    );
  }
}

FeedbackReport _legacyFeedbackReportFromStatus({
  required String sessionId,
  required Map<String, dynamic> transcript,
  required Map<String, dynamic> report,
}) {
  final components = (report['components'] as List<dynamic>? ?? const [])
      .whereType<Map>()
      .map((value) => Map<String, dynamic>.from(value))
      .toList();

  int componentScore(String category) {
    final match = components.where(
      (item) => (item['category']?.toString().toLowerCase() ?? '') == category.toLowerCase(),
    );
    if (match.isEmpty) {
      return 0;
    }
    final raw = match.first['score'];
    if (raw is int) {
      return raw;
    }
    if (raw is double) {
      return raw.round();
    }
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  final paceScore = componentScore('Pace');
  final clarityScore = componentScore('Clarity');
  final confidenceScore = componentScore('Confidence');
  final grammarScore = componentScore('Grammar');
  final fillerScore = ((grammarScore + clarityScore) / 2).round();
  final summary = report['aiComments']?.toString() ?? 'Feedback generated successfully.';

  final strengths = <String>[];
  final weaknesses = <String>[];
  final suggestions = <String>[];

  if (clarityScore >= 70) {
    strengths.add('Your answer was reasonably clear and understandable.');
  } else {
    weaknesses.add('Your answer could be clearer and better structured.');
    suggestions.add('Split the answer into shorter and more organized points.');
  }

  if (confidenceScore >= 70) {
    strengths.add('You sounded fairly confident overall.');
  } else {
    weaknesses.add('Your confidence can improve with steadier delivery.');
    suggestions.add('Finish each sentence with conviction and avoid trailing off.');
  }

  if (paceScore >= 70) {
    strengths.add('Your speaking pace was comfortable for listening.');
  } else {
    weaknesses.add('Your speaking pace needs more control.');
    suggestions.add('Try a steadier pace with short pauses between ideas.');
  }

  if (strengths.isEmpty) {
    strengths.add('You completed the answer and produced enough material for analysis.');
  }
  if (weaknesses.isEmpty) {
    weaknesses.add('There are still a few areas you can refine further.');
  }
  if (suggestions.isEmpty) {
    suggestions.add('Practice the same answer once more and focus on pace, clarity, and confidence.');
  }

  final overallRaw = report['overallScore'];
  final overallScore = overallRaw is int
      ? overallRaw
      : overallRaw is double
          ? overallRaw.round()
          : int.tryParse(overallRaw?.toString() ?? '') ?? 0;

  return FeedbackReport(
    reportId: report['id']?.toString() ?? sessionId,
    sessionId: sessionId,
    overallScore: overallScore,
    paceScore: paceScore,
    clarityScore: clarityScore,
    confidenceScore: confidenceScore,
    fillerScore: fillerScore,
    transcriptText: transcript['text']?.toString() ?? '',
    transcriptHighlights: const [],
    summary: summary,
    strengths: strengths,
    weaknesses: weaknesses,
    suggestions: suggestions,
    betterAnswer: '',
    fillerBreakdown: const [],
    hesitationPhrases: const [],
  );
}
