class SubscriptionSummary {
  const SubscriptionSummary({
    required this.plan,
    required this.developerAccount,
    required this.sessionsUsed,
    required this.sessionLimit,
    required this.sessionsRemaining,
    required this.processedSecondsUsed,
    required this.processedSecondsLimit,
    required this.processedSecondsRemaining,
  });

  final String plan;
  final bool developerAccount;
  final int sessionsUsed;
  final int sessionLimit;
  final int sessionsRemaining;
  final int processedSecondsUsed;
  final int processedSecondsLimit;
  final int processedSecondsRemaining;

  factory SubscriptionSummary.fromJson(Map<String, dynamic> json) {
    return SubscriptionSummary(
      plan: json['plan'] as String,
      developerAccount: json['developerAccount'] as bool? ?? false,
      sessionsUsed: json['sessionsUsed'] as int? ?? 0,
      sessionLimit: json['sessionLimit'] as int? ?? 0,
      sessionsRemaining: json['sessionsRemaining'] as int? ?? 0,
      processedSecondsUsed: json['processedSecondsUsed'] as int? ?? 0,
      processedSecondsLimit: json['processedSecondsLimit'] as int? ?? 0,
      processedSecondsRemaining: json['processedSecondsRemaining'] as int? ?? 0,
    );
  }

  SubscriptionSummary copyWith({
    String? plan,
    bool? developerAccount,
    int? sessionsUsed,
    int? sessionLimit,
    int? sessionsRemaining,
    int? processedSecondsUsed,
    int? processedSecondsLimit,
    int? processedSecondsRemaining,
  }) {
    return SubscriptionSummary(
      plan: plan ?? this.plan,
      developerAccount: developerAccount ?? this.developerAccount,
      sessionsUsed: sessionsUsed ?? this.sessionsUsed,
      sessionLimit: sessionLimit ?? this.sessionLimit,
      sessionsRemaining: sessionsRemaining ?? this.sessionsRemaining,
      processedSecondsUsed: processedSecondsUsed ?? this.processedSecondsUsed,
      processedSecondsLimit: processedSecondsLimit ?? this.processedSecondsLimit,
      processedSecondsRemaining: processedSecondsRemaining ?? this.processedSecondsRemaining,
    );
  }
}
