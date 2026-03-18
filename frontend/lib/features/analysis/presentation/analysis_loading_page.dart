import 'package:flutter/material.dart';

import '../../../app/app_controller.dart';
import 'feedback_report_page.dart';

class AnalysisLoadingPage extends StatefulWidget {
  const AnalysisLoadingPage({
    super.key,
    required this.controller,
    required this.sessionId,
  });

  final VoiceIqAppController controller;
  final String sessionId;

  @override
  State<AnalysisLoadingPage> createState() => _AnalysisLoadingPageState();
}

class _AnalysisLoadingPageState extends State<AnalysisLoadingPage> {
  String? _errorMessage;
  int _activeStep = 1;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    try {
      setState(() => _activeStep = 1);
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) {
        return;
      }
      setState(() => _activeStep = 2);
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) {
        return;
      }
      setState(() => _activeStep = 3);
      final report = await widget.controller.waitForFeedback(widget.sessionId);
      if (!mounted) {
        return;
      }
      setState(() => _activeStep = 4);
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => FeedbackReportPage(report: report),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = [
      ('Transcribing audio', _activeStep > 1, _activeStep == 1),
      ('Detecting filler words', _activeStep > 2, _activeStep == 2),
      ('Analysing tone and pace', _activeStep > 3, _activeStep == 3),
      ('Generating feedback', _activeStep > 4, _activeStep == 4),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
              const Spacer(),
              const Center(child: _DarkWaveform()),
              const SizedBox(height: 28),
              Center(
                child: Text(
                  _errorMessage == null
                      ? 'Analysing your speech...'
                      : 'Analysis paused',
                  style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(height: 28),
              ...steps.map(
                (step) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      if (step.$2)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF22C55E),
                        )
                      else if (step.$3)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF6C63FF),
                          ),
                        )
                      else
                        const Icon(
                          Icons.radio_button_unchecked_rounded,
                          color: Color(0xFF6B7280),
                        ),
                      const SizedBox(width: 12),
                      Text(
                        step.$1,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: step.$2 || step.$3
                              ? Colors.white
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(239, 68, 68, 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color.fromRGBO(248, 113, 113, 0.35),
                    ),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loadReport,
                    child: const Text('Retry status check'),
                  ),
                ),
              ],
              const Spacer(),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 4,
                  value: _activeStep / 4,
                  backgroundColor: const Color.fromRGBO(255, 255, 255, 0.15),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF6C63FF),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Tip: Most people say 'um' 6-8 times per minute without realising.",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFA78BFA),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DarkWaveform extends StatefulWidget {
  const _DarkWaveform();

  @override
  State<_DarkWaveform> createState() => _DarkWaveformState();
}

class _DarkWaveformState extends State<_DarkWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const barWidth = 4.0;
          const barSpacing = 1.5;
          const totalPerBar = barWidth + barSpacing * 2;
          final barCount = (constraints.maxWidth / totalPerBar).floor();
          return AnimatedBuilder(
            animation: _animController,
            builder: (context, _) {
              final t = _animController.value;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(barCount, (index) {
                  // Create a wave that travels across the bars
                  final phase = (index / barCount) * 3.14159 * 2;
                  final wave = (((t * 3.14159 * 2) + phase).remainder(3.14159 * 2));
                  // Use sin to smoothly oscillate bar heights
                  final sin = _fastSin(wave);
                  final height = 16.0 + sin.abs() * 56.0;
                  final opacity = 0.45 + sin.abs() * 0.55;
                  return Container(
                    width: barWidth,
                    height: height,
                    margin: const EdgeInsets.symmetric(horizontal: barSpacing),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withValues(alpha: opacity),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              );
            },
          );
        },
      ),
    );
  }

  /// Fast sine approximation to avoid importing dart:math in the widget
  double _fastSin(double x) {
    // Normalize to [-pi, pi]
    const pi = 3.14159265;
    x = x % (2 * pi);
    if (x > pi) x -= 2 * pi;
    // Bhaskara I approximation
    final abs = x < 0 ? -x : x;
    final result = 16 * x * (pi - abs) / (5 * pi * pi - 4 * x * (pi - abs));
    return result;
  }
}
