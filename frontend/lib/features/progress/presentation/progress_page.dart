import 'package:flutter/material.dart';

import '../../../app/app_controller.dart';
import '../../analysis/data/feedback_report.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key, required this.controller});

  final VoiceIqAppController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final report = controller.latestReport;
    final sessionCount = controller.completedSessionsCount;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your progress', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              sessionCount == 0 ? 'No sessions yet' : 'Latest activity',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            if (sessionCount == 0 || report == null)
              _EmptyProgressCard(onStart: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Record your first answer to unlock progress tracking.'),
                  ),
                );
              })
            else ...[
              _LiveTrendCard(score: report.overallScore),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.55,
                children: [
                  _StatMetricCard(label: 'Total sessions', value: '$sessionCount'),
                  _StatMetricCard(label: 'Best score', value: '${report.overallScore}'),
                  _StatMetricCard(
                    label: 'Confidence',
                    value: '${report.confidenceScore}',
                  ),
                  _StatMetricCard(
                    label: 'Plan',
                    value: controller.subscription?.developerAccount == true
                        ? 'PRO'
                        : (controller.session?.plan ?? 'FREE'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Skill breakdown', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              _SkillBreakdownCard(report: report),
              const SizedBox(height: 20),
              Text('Latest feedback', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              _LatestSummaryCard(summary: report.summary),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyProgressCard extends StatelessWidget {
  const _EmptyProgressCard({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.show_chart_rounded,
                color: Color(0xFF6C63FF),
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your progress will appear here',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Complete your first speaking session and we will start tracking scores, pacing, confidence, and improvement trends.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onStart,
              child: const Text('Start your first session'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveTrendCard extends StatelessWidget {
  const _LiveTrendCard({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 180,
          child: Stack(
            children: [
              Positioned.fill(
                left: 28,
                bottom: 20,
                child: CustomPaint(painter: _TrendPainter(score: score)),
              ),
              Positioned(
                right: 8,
                top: 24,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFC7D2FE)),
                  ),
                  child: Text(
                    'Latest score: $score',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF3730A3),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter({required this.score});

  final int score;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = const Color(0xFF6C63FF).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = const Color(0xFF6C63FF)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final normalized = 1 - (score.clamp(0, 100) / 100.0);
    final points = [
      Offset(0, size.height * ((normalized + 0.18).clamp(0.18, 0.82))),
      Offset(size.width * 0.28, size.height * ((normalized + 0.10).clamp(0.12, 0.75))),
      Offset(size.width * 0.56, size.height * ((normalized + 0.04).clamp(0.08, 0.64))),
      Offset(size.width * 0.80, size.height * (normalized.clamp(0.06, 0.56))),
      Offset(size.width, size.height * ((normalized - 0.02).clamp(0.04, 0.52))),
    ];

    final areaPath = Path()..moveTo(0, size.height);
    for (final point in points) {
      areaPath.lineTo(point.dx, point.dy);
    }
    areaPath.lineTo(size.width, size.height);
    areaPath.close();

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      linePath.lineTo(point.dx, point.dy);
    }

    canvas.drawPath(areaPath, fill);
    canvas.drawPath(linePath, stroke);
    canvas.drawCircle(points.last, 5, Paint()..color = const Color(0xFF6C63FF));
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) {
    return oldDelegate.score != score;
  }
}

class _StatMetricCard extends StatelessWidget {
  const _StatMetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171728) : const Color(0xFFF8F8FC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
        ],
      ),
    );
  }
}

class _SkillBreakdownCard extends StatelessWidget {
  const _SkillBreakdownCard({required this.report});

  final FeedbackReport report;

  @override
  Widget build(BuildContext context) {
    final skills = [
      ('Pace', report.paceScore),
      ('Clarity', report.clarityScore),
      ('Confidence', report.confidenceScore),
      ('Filler words', report.fillerScore),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: skills
              .map(
                (skill) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: [
                      SizedBox(width: 94, child: Text(skill.$1)),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: skill.$2 / 100,
                            minHeight: 8,
                            backgroundColor: const Color(0xFFF3F4F6),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('${skill.$2}%'),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _LatestSummaryCard extends StatelessWidget {
  const _LatestSummaryCard({required this.summary});

  final String summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(summary, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}
