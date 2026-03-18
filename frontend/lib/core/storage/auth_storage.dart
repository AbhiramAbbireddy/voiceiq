import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/data/auth_session.dart';

class AuthStorage {
  AuthStorage() : _storage = const FlutterSecureStorage();

  static const _sessionKey = 'voiceiq_auth_session';

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
}
