import 'dart:math';

class AuthSession {
  const AuthSession({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.targetRole,
    required this.plan,
    required this.token,
  });

  final String userId;
  final String fullName;
  final String email;
  final String targetRole;
  final String plan;
  final String token;

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) {
      return 'VI';
    }
    if (parts.length == 1) {
      final first = parts.first;
      return first.substring(0, min(2, first.length)).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      userId: json['userId'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      targetRole: json['targetRole'] as String,
      plan: json['plan'] as String,
      token: json['token'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'targetRole': targetRole,
      'plan': plan,
      'token': token,
    };
  }

  AuthSession copyWith({
    String? fullName,
    String? email,
    String? targetRole,
    String? plan,
    String? token,
  }) {
    return AuthSession(
      userId: userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      targetRole: targetRole ?? this.targetRole,
      plan: plan ?? this.plan,
      token: token ?? this.token,
    );
  }
}
