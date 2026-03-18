import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import 'speech_models.dart';

class SpeechRepository {
  SpeechRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<VoiceSession> createSession({
    required String promptText,
  }) {
    return _apiClient.post<VoiceSession>(
      '/api/v1/speech/sessions',
      data: {
        'type': 'VOICE_RECORDER',
        'promptText': promptText,
      },
      parser: VoiceSession.fromJson,
    );
  }

  Future<UploadPreparation> initiateUpload({
    required String sessionId,
    required String originalFileName,
    required String mimeType,
  }) {
    return _apiClient.post<UploadPreparation>(
      '/api/v1/speech/sessions/$sessionId/initiate-upload',
      data: {
        'originalFileName': originalFileName,
        'mimeType': mimeType,
      },
      parser: UploadPreparation.fromJson,
    );
  }

  Future<void> uploadToStorage({
    required UploadPreparation preparation,
    required File file,
    required String mimeType,
    int durationSeconds = 0,
  }) async {
    if (preparation.uploadType == 'DIRECT_PUT') {
      final bytes = await file.readAsBytes();
      await _apiClient.putBytes(
        preparation.uploadUrl,
        bytes: bytes,
        headers: {
          'Content-Type': mimeType,
          ...preparation.requiredHeaders,
        },
      );
      return;
    }

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.uri.pathSegments.last,
      ),
      'mimeType': mimeType,
      'durationSeconds': durationSeconds.toString(),
    });

    await _apiClient.postMultipart<RecordingUploadResult>(
      '${_resolveBackendPath(preparation.uploadUrl)}?durationSeconds=$durationSeconds&mimeType=$mimeType',
      formData: formData,
      parser: RecordingUploadResult.fromJson,
    );
  }

  Future<RecordingUploadResult> completeUpload({
    required String sessionId,
    required String objectKey,
    required String originalFileName,
    required String mimeType,
    int durationSeconds = 0,
  }) {
    return _apiClient.post<RecordingUploadResult>(
      '/api/v1/speech/sessions/$sessionId/complete-upload',
      data: {
        'objectKey': objectKey,
        'originalFileName': originalFileName,
        'mimeType': mimeType,
        'durationSeconds': durationSeconds,
      },
      parser: RecordingUploadResult.fromJson,
    );
  }

  Future<SessionStatusModel> getSessionStatus(String sessionId) {
    return _apiClient.get<SessionStatusModel>(
      '/api/v1/speech/sessions/$sessionId/status',
      SessionStatusModel.fromJson,
    );
  }

  String _resolveBackendPath(String uploadUrl) {
    if (uploadUrl.startsWith('http://') || uploadUrl.startsWith('https://')) {
      return uploadUrl;
    }
    return uploadUrl;
  }
}
