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
  });

  final String sessionId;
  final String status;
  final bool reportReady;
  final bool transcriptReady;
  final String message;

  factory SessionStatusModel.fromJson(Map<String, dynamic> json) {
    return SessionStatusModel(
      sessionId: json['sessionId'] as String,
      status: json['status'] as String? ?? 'CREATED',
      reportReady: json['reportReady'] as bool? ?? false,
      transcriptReady: json['transcriptReady'] as bool? ?? false,
      message: json['message'] as String? ?? '',
    );
  }
}
