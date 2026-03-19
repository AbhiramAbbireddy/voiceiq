import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../data/feedback_report.dart';

class FeedbackReportPage extends StatelessWidget {
  const FeedbackReportPage({super.key, required this.report});

  final FeedbackReport report;

  Future<void> _copyReport(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _buildExportText()));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report copied to clipboard.')),
      );
    }
  }

  Future<void> _saveReport(BuildContext context) async {
    final directory = await getApplicationDocumentsDirectory();
    final safeSessionId = report.sessionId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final file = File('${directory.path}${Platform.pathSeparator}voiceiq-report-$safeSessionId.txt');
    await file.writeAsString(_buildExportText());
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report saved to ${file.path}')),
      );
    }
  }

  String _buildExportText() {
    final buffer = StringBuffer()
      ..writeln('VoiceIQ Session Report')
      ..writeln('Session ID: ${report.sessionId}')
      ..writeln('Overall Score: ${report.overallScore}/100')
      ..writeln('Pace: ${report.paceScore}')
      ..writeln('Clarity: ${report.clarityScore}')
      ..writeln('Confidence: ${report.confidenceScore}')
      ..writeln('Filler Words: ${report.fillerScore}')
      ..writeln()
      ..writeln('Summary')
      ..writeln(report.summary)
      ..writeln()
      ..writeln('Transcript')
      ..writeln(report.transcriptText);

    if (report.strengths.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Strengths');
      for (final item in report.strengths) {
        buffer.writeln('- $item');
      }
    }

    if (report.weaknesses.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Needs work');
      for (final item in report.weaknesses) {
        buffer.writeln('- $item');
      }
    }

    if (report.suggestions.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Suggestions');
      for (final item in report.suggestions) {
        buffer.writeln('- $item');
      }
    }

    if (report.betterAnswer.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Better way to say it')
        ..writeln(report.betterAnswer);
    }

    return buffer.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  Expanded(
                    child: Text(
                      'Session report',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _copyReport(context),
                    icon: const Icon(Icons.ios_share_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _OverallScoreCard(report: report),
                    const SizedBox(height: 16),
                    _DetailedBreakdownCard(report: report),
                    const SizedBox(height: 16),
                    _TranscriptCard(report: report),
                    const SizedBox(height: 16),
                    _SuggestionsSection(report: report),
                    if (report.betterAnswer.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Card(
                        color: isDark ? const Color(0xFF171728) : Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Better way to say it',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                report.betterAnswer,
                                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: const Border(
            top: BorderSide(color: Color.fromRGBO(0, 0, 0, 0.06), width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Practise again'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => _saveReport(context),
                  child: const Text('Save report'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverallScoreCard extends StatelessWidget {
  const _OverallScoreCard({required this.report});

  final FeedbackReport report;

  @override
  Widget build(BuildContext context) {
    final improvementTone = report.overallScore >= 75
        ? const Color(0xFF22C55E)
        : report.overallScore >= 60
        ? const Color(0xFFF59E0B)
        : const Color(0xFFEF4444);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _ScoreRing(score: report.overallScore, size: 160, label: '/ 100'),
          const SizedBox(height: 16),
          Text(
            report.summary,
            textAlign: TextAlign.center,
            style: TextStyle(color: improvementTone, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({
    required this.score,
    required this.size,
    required this.label,
  });

  final int score;
  final double size;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 10,
              backgroundColor: const Color.fromRGBO(255, 255, 255, 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$score',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: Color(0xFFA78BFA), fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailedBreakdownCard extends StatelessWidget {
  const _DetailedBreakdownCard({required this.report});

  final FeedbackReport report;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Detailed breakdown', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _BreakdownRow(
              label: 'Pace',
              score: report.paceScore,
              color: _metricColor(report.paceScore),
              icon: Icons.speed_rounded,
            ),
            const SizedBox(height: 14),
            _BreakdownRow(
              label: 'Clarity',
              score: report.clarityScore,
              color: _metricColor(report.clarityScore),
              icon: Icons.record_voice_over_rounded,
            ),
            const SizedBox(height: 14),
            _BreakdownRow(
              label: 'Confidence',
              score: report.confidenceScore,
              color: _metricColor(report.confidenceScore),
              icon: Icons.psychology_alt_rounded,
            ),
            const SizedBox(height: 14),
            _BreakdownRow(
              label: 'Filler words',
              score: report.fillerScore,
              color: _metricColor(report.fillerScore),
              icon: Icons.warning_amber_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Color _metricColor(int score) {
    if (score >= 80) {
      return const Color(0xFF22C55E);
    }
    if (score >= 60) {
      return const Color(0xFFF59E0B);
    }
    return const Color(0xFFEF4444);
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.score,
    required this.color,
    required this.icon,
  });

  final String label;
  final int score;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Icon(icon, size: 22, color: iconColor),
        const SizedBox(width: 12),
        SizedBox(
          width: 90,
          child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 6,
              backgroundColor: const Color(0xFFF3F4F6),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text('$score', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _TranscriptCard extends StatelessWidget {
  const _TranscriptCard({required this.report});

  final FeedbackReport report;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your transcript', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _TranscriptText(
              transcriptText: report.transcriptText,
              highlights: report.transcriptHighlights,
            ),
            if (report.transcriptHighlights.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Text(
                  report.transcriptHighlights.first.message,
                  style: const TextStyle(color: Color(0xFF92400E), fontSize: 13),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TranscriptText extends StatelessWidget {
  const _TranscriptText({
    required this.transcriptText,
    required this.highlights,
  });

  final String transcriptText;
  final List<TranscriptHighlight> highlights;

  @override
  Widget build(BuildContext context) {
    if (transcriptText.isEmpty) {
      return Text(
        'Transcript will appear here after analysis.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    final normalized = [...highlights]..sort(
      (left, right) => left.startIndex.compareTo(right.startIndex),
    );

    final spans = <InlineSpan>[];
    var currentIndex = 0;
    for (final highlight in normalized) {
      final safeStart = highlight.startIndex.clamp(0, transcriptText.length);
      final safeEnd = highlight.endIndex.clamp(safeStart, transcriptText.length);
      if (safeStart > currentIndex) {
        spans.add(TextSpan(text: transcriptText.substring(currentIndex, safeStart)));
      }
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              transcriptText.substring(safeStart, safeEnd),
              style: const TextStyle(
                color: Color(0xFF92400E),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ),
      );
      currentIndex = safeEnd;
    }
    if (currentIndex < transcriptText.length) {
      spans.add(TextSpan(text: transcriptText.substring(currentIndex)));
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 14,
          height: 1.6,
        ),
        children: spans,
      ),
    );
  }
}

class _SuggestionsSection extends StatelessWidget {
  const _SuggestionsSection({required this.report});

  final FeedbackReport report;

  @override
  Widget build(BuildContext context) {
    final cards = <_SuggestionCardData>[
      ...report.weaknesses.map(
        (item) => _SuggestionCardData(
          title: 'Needs work',
          body: item,
          borderColor: const Color(0xFFEF4444),
          titleColor: const Color(0xFFEF4444),
        ),
      ),
      ...report.suggestions.map(
        (item) => _SuggestionCardData(
          title: 'Suggested improvement',
          body: item,
          borderColor: const Color(0xFFF59E0B),
          titleColor: const Color(0xFFF59E0B),
        ),
      ),
      ...report.strengths.map(
        (item) => _SuggestionCardData(
          title: 'What is already working',
          body: item,
          borderColor: const Color(0xFF22C55E),
          titleColor: const Color(0xFF22C55E),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How to improve', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ...cards.map(
          (card) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SuggestionCard(data: card),
          ),
        ),
      ],
    );
  }
}

class _SuggestionCardData {
  const _SuggestionCardData({
    required this.title,
    required this.body,
    required this.borderColor,
    required this.titleColor,
  });

  final String title;
  final String body;
  final Color borderColor;
  final Color titleColor;
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.data});

  final _SuggestionCardData data;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171728) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.08),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 120,
            decoration: BoxDecoration(
              color: data.borderColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: TextStyle(
                      color: data.titleColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data.body,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.45),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
