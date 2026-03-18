import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/config/app_environment.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../core/storage/auth_storage.dart';
import '../features/analysis/data/feedback_report.dart';
import '../features/analysis/data/feedback_repository.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/auth_session.dart';
import '../features/speech/data/speech_repository.dart';
import '../features/subscription/data/subscription_repository.dart';
import '../features/subscription/data/subscription_summary.dart';

class VoiceIqAppController extends ChangeNotifier {
  VoiceIqAppController()
    : _authStorage = AuthStorage(),
      _bootstrapping = true,
      _authBusy = false {
    _apiClient = ApiClient(
      baseUrl: AppEnvironment.baseUrl,
      tokenProvider: () async => _session?.token,
    );
    _authRepository = AuthRepository(_apiClient);
    _speechRepository = SpeechRepository(_apiClient);
    _feedbackRepository = FeedbackRepository(_apiClient);
    _subscriptionRepository = SubscriptionRepository(_apiClient);
  }

  final AuthStorage _authStorage;
  late final ApiClient _apiClient;
  late final AuthRepository _authRepository;
  late final SpeechRepository _speechRepository;
  late final FeedbackRepository _feedbackRepository;
  late final SubscriptionRepository _subscriptionRepository;

  bool _bootstrapping;
  bool _authBusy;
  AuthSession? _session;
  SubscriptionSummary? _subscription;
  FeedbackReport? _latestReport;

  bool get isBootstrapping => _bootstrapping;
  bool get isAuthBusy => _authBusy;
  bool get isAuthenticated => _session != null;
  AuthSession? get session => _session;
  SubscriptionSummary? get subscription => _subscription;
  FeedbackReport? get latestReport => _latestReport;

  Future<void> initialize() async {
    try {
      _session = await _authStorage.readSession();
      if (_session != null) {
        await refreshSubscription();
      }
    } catch (_) {
      await _authStorage.clearSession();
      _session = null;
    } finally {
      _bootstrapping = false;
      notifyListeners();
    }
  }

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
    required String targetRole,
  }) async {
    _authBusy = true;
    notifyListeners();
    try {
      _session = await _authRepository.register(
        fullName: fullName,
        email: email,
        password: password,
        targetRole: targetRole,
      );
      await _authStorage.saveSession(_session!);
      await refreshSubscription();
    } finally {
      _authBusy = false;
      notifyListeners();
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    _authBusy = true;
    notifyListeners();
    try {
      _session = await _authRepository.login(email: email, password: password);
      await _authStorage.saveSession(_session!);
      await refreshSubscription();
    } finally {
      _authBusy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _session = null;
    _subscription = null;
    _latestReport = null;
    await _authStorage.clearSession();
    notifyListeners();
  }

  Future<void> updateLocalProfile({
    required String fullName,
    required String targetRole,
  }) async {
    final current = _session;
    if (current == null) {
      return;
    }
    _session = current.copyWith(
      fullName: fullName.trim(),
      targetRole: targetRole.trim(),
    );
    await _authStorage.saveSession(_session!);
    notifyListeners();
  }

  Future<SubscriptionSummary?> refreshSubscription() async {
    if (_session == null) {
      _subscription = null;
      notifyListeners();
      return null;
    }

    try {
      _subscription = await _subscriptionRepository.getCurrentSubscription();
      if (_subscription != null && _session != null) {
        _session = _session!.copyWith(plan: _subscription!.plan);
        await _authStorage.saveSession(_session!);
      }
      notifyListeners();
      return _subscription;
    } on ApiException {
      rethrow;
    }
  }

  Future<String> submitAudioAnalysis({
    required String promptText,
    required String filePath,
    int durationSeconds = 0,
  }) async {
    final file = File(filePath);
    final fileName = file.uri.pathSegments.isEmpty
        ? 'recording.m4a'
        : file.uri.pathSegments.last;
    final mimeType = _guessMimeType(fileName);

    final session = await _speechRepository.createSession(promptText: promptText);
    final preparation = await _speechRepository.initiateUpload(
      sessionId: session.sessionId,
      originalFileName: fileName,
      mimeType: mimeType,
    );

    await _speechRepository.uploadToStorage(
      preparation: preparation,
      file: file,
      mimeType: mimeType,
      durationSeconds: durationSeconds,
    );

    if (preparation.uploadType == 'DIRECT_PUT') {
      final objectKey = preparation.objectKey;
      if (objectKey == null || objectKey.isEmpty) {
        throw ApiException('Upload finished but object key is missing');
      }
      await _speechRepository.completeUpload(
        sessionId: session.sessionId,
        objectKey: objectKey,
        originalFileName: fileName,
        mimeType: mimeType,
        durationSeconds: durationSeconds,
      );
    }

    return session.sessionId;
  }

  Future<FeedbackReport> waitForFeedback(String sessionId) async {
    for (var attempt = 0; attempt < 45; attempt++) {
      final status = await _speechRepository.getSessionStatus(sessionId);
      if (status.status == 'COMPLETED' || status.reportReady) {
        final report = await _feedbackRepository.getReport(sessionId);
        _latestReport = report;
        notifyListeners();
        return report;
      }
      if (status.status == 'FAILED') {
        throw ApiException(
          status.message.isEmpty
              ? 'Analysis failed. Please try again.'
              : status.message,
        );
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }

    throw ApiException('Analysis is taking longer than expected. Please try again.');
  }

  String _guessMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return switch (extension) {
      'wav' => 'audio/wav',
      'mp3' => 'audio/mpeg',
      'aac' => 'audio/aac',
      'ogg' => 'audio/ogg',
      _ => 'audio/m4a',
    };
  }
}
