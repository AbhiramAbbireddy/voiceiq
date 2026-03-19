import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/analysis/data/feedback_report.dart';
import '../../features/auth/data/auth_session.dart';

class AuthStorage {
  AuthStorage() : _storage = const FlutterSecureStorage();

  static const _sessionKey = 'voiceiq_auth_session';
  static const _latestReportKey = 'voiceiq_latest_report';
  static const _completedSessionsKey = 'voiceiq_completed_sessions';

  final FlutterSecureStorage _storage;

  Future<void> saveSession(AuthSession session) async {
    await _storage.write(key: _sessionKey, value: jsonEncode(session.toJson()));
  }

  Future<AuthSession?> readSession() async {
    final raw = await _storage.read(key: _sessionKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return AuthSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> clearSession() => _storage.delete(key: _sessionKey);

  Future<void> saveLatestReport(FeedbackReport report) {
    return _storage.write(key: _latestReportKey, value: jsonEncode(report.toJson()));
  }

  Future<FeedbackReport?> readLatestReport() async {
    final raw = await _storage.read(key: _latestReportKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return FeedbackReport.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> clearLatestReport() => _storage.delete(key: _latestReportKey);

  Future<void> saveCompletedSessionsCount(int count) {
    return _storage.write(key: _completedSessionsKey, value: count.toString());
  }

  Future<int> readCompletedSessionsCount() async {
    final raw = await _storage.read(key: _completedSessionsKey);
    return int.tryParse(raw ?? '') ?? 0;
  }

  Future<void> clearCompletedSessionsCount() => _storage.delete(key: _completedSessionsKey);

  Future<void> clearAll() async {
    await clearSession();
    await clearLatestReport();
    await clearCompletedSessionsCount();
  }
}
