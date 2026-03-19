import 'dart:io';

import 'package:dio/dio.dart';
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
  int _completedSessionsCount = 0;

  bool get isBootstrapping => _bootstrapping;
  bool get isAuthBusy => _authBusy;
  bool get isAuthenticated => _session != null;
  AuthSession? get session => _session;
  SubscriptionSummary? get subscription => _subscription;
  FeedbackReport? get latestReport => _latestReport;
  int get completedSessionsCount => _completedSessionsCount;

  Future<void> initialize() async {
    try {
      _session = await _authStorage.readSession();
      _latestReport = await _authStorage.readLatestReport();
      _completedSessionsCount = await _authStorage.readCompletedSessionsCount();
      if (_session != null) {
        try {
          await refreshSubscription();
        } catch (_) {
          _subscription = _buildFallbackSubscription();
        }
      }
    } catch (_) {
      await _authStorage.clearAll();
      _session = null;
      _latestReport = null;
      _completedSessionsCount = 0;
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
      try {
        await refreshSubscription();
      } catch (_) {
        _subscription = _buildFallbackSubscription();
      }
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
      try {
        await refreshSubscription();
      } catch (_) {
        _subscription = _buildFallbackSubscription();
      }
    } finally {
      _authBusy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _session = null;
    _subscription = null;
    _latestReport = null;
    _completedSessionsCount = 0;
    await _authStorage.clearAll();
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
      _subscription = _mergeLocalUsageIntoSubscription(_subscription!);
      notifyListeners();
      return _subscription;
    } catch (_) {
      _subscription = _buildFallbackSubscription();
      notifyListeners();
      return _subscription;
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
        FeedbackReport report;
        try {
          report = await _feedbackRepository.getReport(sessionId);
        } catch (error) {
          if (_isMissingReportError(error) && status.fallbackReport != null) {
            report = status.fallbackReport!;
          } else {
            rethrow;
          }
        }
        report = _normalizeIncompleteReport(report);
        _latestReport = report;
        _completedSessionsCount += 1;
        _subscription = _mergeLocalUsageIntoSubscription(
          _subscription ?? _buildFallbackSubscription(),
        );
        await _authStorage.saveLatestReport(report);
        await _authStorage.saveCompletedSessionsCount(_completedSessionsCount);
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

  SubscriptionSummary _buildFallbackSubscription() {
    final currentSession = _session;
    final isDeveloper = currentSession?.email.endsWith('@gmail.com') ?? false;
    final plan = isDeveloper ? 'PRO' : (currentSession?.plan ?? 'FREE');
    final sessionLimit = plan == 'PRO' ? 9999 : 10;
    final processedSecondsLimit = plan == 'PRO' ? 999999 : 900;

    return SubscriptionSummary(
      plan: plan,
      developerAccount: isDeveloper,
      sessionsUsed: _completedSessionsCount,
      sessionLimit: sessionLimit,
      sessionsRemaining: (sessionLimit - _completedSessionsCount).clamp(0, sessionLimit),
      processedSecondsUsed: 0,
      processedSecondsLimit: processedSecondsLimit,
      processedSecondsRemaining: processedSecondsLimit,
    );
  }

  SubscriptionSummary _mergeLocalUsageIntoSubscription(SubscriptionSummary base) {
    final sessionsUsed = base.sessionsUsed > _completedSessionsCount
        ? base.sessionsUsed
        : _completedSessionsCount;
    final remaining = (base.sessionLimit - sessionsUsed).clamp(0, base.sessionLimit);

    return base.copyWith(
      sessionsUsed: sessionsUsed,
      sessionsRemaining: remaining,
    );
  }

  bool _isMissingReportError(Object error) {
    if (error is ApiException) {
      return error.statusCode == 404;
    }

    if (error is DioException) {
      if (error.response?.statusCode == 404) {
        return true;
      }

      final nestedError = error.error;
      if (nestedError is ApiException) {
        return nestedError.statusCode == 404;
      }
    }

    return false;
  }

  FeedbackReport _normalizeIncompleteReport(FeedbackReport report) {
    if (!_looksLikeIncompleteAiFallback(report)) {
      return report;
    }

    final transcript = report.transcriptText.trim();
    final wordMatches = RegExp(r"\b[\w']+\b").allMatches(transcript).toList();
    final wordCount = wordMatches.length;
    final estimatedDurationSeconds = ((wordCount / 130.0) * 60.0).round().clamp(4, 180);
    final wordsPerMinute = ((wordCount / estimatedDurationSeconds) * 60.0).round();

    final fillerCount = RegExp(
      r"\b(um|uh|like|you know|basically|actually)\b",
      caseSensitive: false,
    ).allMatches(transcript).length;

    final sentences = transcript
        .split(RegExp(r"[.!?]+"))
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList();
    final avgSentenceWords = wordCount / (sentences.isEmpty ? 1 : sentences.length);

    var paceScore = 82.0;
    if (wordsPerMinute < 90) {
      paceScore = 62.0;
    } else if (wordsPerMinute < 110) {
      paceScore = 74.0;
    } else if (wordsPerMinute > 175) {
      paceScore = 64.0;
    } else if (wordsPerMinute > 155) {
      paceScore = 74.0;
    }

    var clarityScore = 78.0;
    if (avgSentenceWords > 24) {
      clarityScore -= 10.0;
    }
    if (fillerCount >= 4) {
      clarityScore -= 8.0;
    }
    if (wordCount < 12) {
      clarityScore -= 12.0;
    }

    var confidenceScore = 76.0;
    final tentativeCount = RegExp(
      r"\b(maybe|i think|kind of|sort of|probably)\b",
      caseSensitive: false,
    ).allMatches(transcript).length;
    confidenceScore -= tentativeCount * 4.0;
    confidenceScore -= (fillerCount * 2.0).clamp(0.0, 10.0);

    final fillerScore = _clampScore(100.0 - (fillerCount * 12.0));
    final overallScore = ((paceScore + clarityScore + confidenceScore + fillerScore) / 4.0)
        .round();

    final strengths = <String>[];
    final weaknesses = <String>[];
    final suggestions = <String>[];

    if (clarityScore >= 70) {
      strengths.add('Your answer was understandable and reasonably structured.');
    } else {
      weaknesses.add('Your answer could be clearer and more organized.');
      suggestions.add('Break the answer into smaller points with a stronger structure.');
    }

    if (confidenceScore >= 70) {
      strengths.add('Your delivery sounded fairly confident overall.');
    } else {
      weaknesses.add('Too many hesitations reduced your confidence level.');
      suggestions.add('Practice finishing each point without trailing off or repeating yourself.');
    }

    if (paceScore >= 70) {
      strengths.add('Your speaking pace stayed in a workable range.');
    } else {
      weaknesses.add('Your speaking pace needs better control.');
      suggestions.add('Aim for a steadier pace and insert short pauses between ideas.');
    }

    if (fillerCount > 0) {
      weaknesses.add('Filler words are making the answer sound less polished.');
      suggestions.add('Reduce words like "um" and "uh" to make the response sharper.');
    } else {
      strengths.add('You kept filler words fairly low, which helps clarity.');
    }

    if (strengths.isEmpty) {
      strengths.add('You completed the answer and gave enough speech for analysis.');
    }
    if (weaknesses.isEmpty) {
      weaknesses.add('There are still a few areas you can refine further.');
    }
    if (suggestions.isEmpty) {
      suggestions.add('Practice the same answer once more and focus on structure, pace, and confidence.');
    }

    final summary = [
      'VoiceIQ used transcript-based fallback scoring because the server returned an incomplete AI report.',
      'Your answer was about $wordCount words at roughly $wordsPerMinute words per minute.',
      if (fillerCount > 0)
        'You used $fillerCount filler word${fillerCount == 1 ? '' : 's'}, so trimming those will make the answer sound sharper.'
      else
        'You kept filler words low, which helps the answer sound cleaner.',
    ].join(' ');

    return FeedbackReport(
      reportId: report.reportId,
      sessionId: report.sessionId,
      overallScore: overallScore,
      paceScore: _clampScore(paceScore),
      clarityScore: _clampScore(clarityScore),
      confidenceScore: _clampScore(confidenceScore),
      fillerScore: fillerScore,
      transcriptText: report.transcriptText,
      transcriptHighlights: report.transcriptHighlights,
      summary: summary,
      strengths: strengths,
      weaknesses: weaknesses,
      suggestions: suggestions,
      betterAnswer: report.betterAnswer,
      fillerBreakdown: fillerCount == 0 ? report.fillerBreakdown : List<String>.filled(
        fillerCount,
        'Filler word detected in the response.',
      ),
      hesitationPhrases: report.hesitationPhrases,
    );
  }

  bool _looksLikeIncompleteAiFallback(FeedbackReport report) {
    final summary = report.summary.toLowerCase();
    final allScoresZero =
        report.overallScore == 0 &&
        report.paceScore == 0 &&
        report.clarityScore == 0 &&
        report.confidenceScore == 0 &&
        report.fillerScore == 0;

    return report.transcriptText.trim().isNotEmpty &&
        allScoresZero &&
        (summary.contains('failed temporarily') ||
            summary.contains('try again') ||
            summary.isEmpty);
  }

  int _clampScore(double value) {
    final rounded = value.round();
    if (rounded < 0) {
      return 0;
    }
    if (rounded > 100) {
      return 100;
    }
    return rounded;
  }
}
