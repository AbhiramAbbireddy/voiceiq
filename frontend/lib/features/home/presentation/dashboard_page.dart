import 'package:flutter/material.dart';

import '../../../app/app_controller.dart';
import '../../analysis/data/feedback_report.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.controller,
    required this.onOpenRecord,
    required this.onOpenProgress,
    required this.onOpenProfile,
    required this.onOpenLibrary,
    required this.onOpenReport,
    required this.onOpenMockInterview,
  });

  final VoiceIqAppController controller;
  final VoidCallback onOpenRecord;
  final VoidCallback onOpenProgress;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenLibrary;
  final VoidCallback onOpenReport;
  final VoidCallback onOpenMockInterview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fullName = controller.session?.fullName ?? 'there';
    final firstName = fullName.trim().split(' ').first;
    final latestReport = controller.latestReport;
    final subscription = controller.subscription;
    final sessionCount = subscription?.sessionsUsed ?? 0;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good morning, $firstName',
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your next confident answer starts today.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: onOpenProfile,
                  borderRadius: BorderRadius.circular(9999),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2B2948) : const Color(0xFFDEDDF7),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      controller.session?.initials.substring(0, 1) ?? 'V',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _StreakCard(sessionCount: sessionCount),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.mic_none_rounded,
                    label: 'Record',
                    onTap: onOpenRecord,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Mock',
                    onTap: onOpenMockInterview,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.show_chart_rounded,
                    label: 'Progress',
                    onTap: onOpenProgress,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.menu_book_rounded,
                    label: 'Library',
                    onTap: onOpenLibrary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _LastSessionCard(
              report: latestReport,
              subscriptionLabel: subscription?.developerAccount == true
                  ? 'Developer Pro'
                  : subscription?.plan ?? 'Free',
              onOpenReport: onOpenReport,
            ),
            const SizedBox(height: 16),
            const _TodayTipCard(),
          ],
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.sessionCount});

  final int sessionCount;

  @override
  Widget build(BuildContext context) {
    final streakDays = sessionCount == 0 ? 0 : sessionCount.clamp(1, 7);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF2D2B55)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streakDays day streak',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  sessionCount == 0
                      ? 'Start your first practice to build momentum'
                      : "Keep going - you're on a roll",
                  style: TextStyle(
                    color: Color(0xFFA78BFA),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: List.generate(7, (index) {
              final isFuture = index >= streakDays;
              final isToday = sessionCount > 0 && index == streakDays - 1;
              final isDone = index < streakDays - (sessionCount > 0 ? 1 : 0);
              return Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? const Color(0xFF6C63FF)
                      : isFuture
                          ? const Color.fromRGBO(255, 255, 255, 0.2)
                          : Colors.white,
                  border: isToday
                      ? Border.all(color: const Color(0xFF6C63FF), width: 3)
                      : null,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 88,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF171728) : const Color(0xFFF8F8FC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? const Color.fromRGBO(255, 255, 255, 0.08)
                : const Color.fromRGBO(0, 0, 0, 0.08),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: theme.colorScheme.onSurface, size: 24),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}

class _LastSessionCard extends StatelessWidget {
  const _LastSessionCard({
    required this.report,
    required this.subscriptionLabel,
    required this.onOpenReport,
  });

  final FeedbackReport? report;
  final String subscriptionLabel;
  final VoidCallback onOpenReport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final report = this.report;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Last session', style: theme.textTheme.titleMedium),
                const Spacer(),
                Text(subscriptionLabel, style: theme.textTheme.labelSmall),
              ],
            ),
            const SizedBox(height: 16),
            if (report == null) ...[
              Text(
                'No completed sessions yet. Record one answer and your first report will show up here.',
                style: theme.textTheme.bodyMedium,
              ),
            ] else ...[
              const _MiniWaveform(),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetricPill(
                    text: 'Pace: ${report.paceScore}',
                    backgroundColor: Color(0xFFDCFCE7),
                    foregroundColor: Color(0xFF166534),
                  ),
                  _MetricPill(
                    text: 'Fillers: ${report.fillerScore}',
                    backgroundColor: Color(0xFFFEF3C7),
                    foregroundColor: Color(0xFFB45309),
                  ),
                  _MetricPill(
                    text: 'Confidence: ${report.confidenceScore}%',
                    backgroundColor: Color(0xFFEEF2FF),
                    foregroundColor: Color(0xFF6C63FF),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: onOpenReport,
                  child: const Text(
                    'View full report',
                    style: TextStyle(
                      color: Color(0xFF6C63FF),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TodayTipCard extends StatelessWidget {
  const _TodayTipCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? const Color(0xFFC7D2FE) : const Color(0xFF3730A3);
    final bodyColor = isDark ? const Color(0xFFE0E7FF) : const Color(0xFF4338CA);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF221F43) : const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_rounded, color: Color(0xFF6C63FF)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's tip",
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Try pausing for 1 second instead of saying 'um'. It signals confidence.",
                  style: TextStyle(
                    color: bodyColor,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniWaveform extends StatelessWidget {
  const _MiniWaveform();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Row(
        children: List.generate(24, (index) {
          final height = 10.0 + (index % 5) * 4.0;
          return Expanded(
            child: Align(
              alignment: Alignment.center,
              child: Container(
                width: 5,
                height: height,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.text,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String text;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
