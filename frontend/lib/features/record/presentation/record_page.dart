import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class RecordPage extends StatefulWidget {
  const RecordPage({
    super.key,
    required this.onAnalyse,
    required this.isSubmitting,
  });

  final Future<void> Function(
    String promptText,
    String filePath,
    String fileName,
    String mimeType,
    int durationSeconds,
  )
  onAnalyse;
  final bool isSubmitting;

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  static const List<String> _prompts = [
    'Tell me about yourself and your professional background.',
    'Describe a time you had to handle a difficult team conflict.',
    'What is your biggest professional achievement so far?',
    'How do you prioritise tasks when everything feels urgent?',
    'Tell me about a challenging problem you solved recently.',
    'Why are you interested in this role and company?',
    'Describe a situation where you had to learn something quickly.',
    'How do you handle negative feedback from a manager?',
    'Walk me through a project you led from start to finish.',
    'Where do you see yourself professionally in five years?',
  ];

  final AudioRecorder _recorder = AudioRecorder();
  final Random _random = Random();
  late String _promptText;
  int _promptIndex = 0;

  bool _isRecording = false;
  bool _isPaused = false;
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  String? _recordedFilePath;

  @override
  void initState() {
    super.initState();
    _promptIndex = _random.nextInt(_prompts.length);
    _promptText = _prompts[_promptIndex];
  }

  void _shufflePrompt() {
    setState(() {
      _promptIndex = (_promptIndex + 1 + _random.nextInt(_prompts.length - 1)) % _prompts.length;
      _promptText = _prompts[_promptIndex];
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _toggleMic() async {
    if (!_isRecording) {
      await _startRecording();
      return;
    }

    if (_isPaused) {
      await _resumeRecording();
    } else {
      await _pauseRecording();
    }
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please allow microphone access to record audio.')),
      );
      return;
    }

    final directory = await getTemporaryDirectory();
    final filePath =
        '${directory.path}${Platform.pathSeparator}voiceiq_${DateTime.now().millisecondsSinceEpoch}.m4a';

    try {
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: filePath,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start recording: $e')),
      );
      return;
    }

    _timer?.cancel();
    _elapsed = Duration.zero;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _isPaused) {
        return;
      }
      setState(() => _elapsed += const Duration(seconds: 1));
    });

    setState(() {
      _isRecording = true;
      _isPaused = false;
      _recordedFilePath = null;
    });
  }

  Future<void> _pauseRecording() async {
    if (!await _recorder.isRecording()) {
      return;
    }
    await _recorder.pause();
    setState(() => _isPaused = true);
  }

  Future<void> _resumeRecording() async {
    await _recorder.resume();
    setState(() => _isPaused = false);
  }

  Future<void> _cancelRecording() async {
    _timer?.cancel();
    await _recorder.stop();
    setState(() {
      _isRecording = false;
      _isPaused = false;
      _elapsed = Duration.zero;
      _recordedFilePath = null;
    });
  }

  Future<void> _stopAndAnalyseRecording() async {
    _timer?.cancel();
    final path = await _recorder.stop();
    if (path == null || path.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recorded file could not be saved. Please try again.')),
      );
      setState(() {
        _isRecording = false;
        _isPaused = false;
      });
      return;
    }

    final file = File(path);
    final fileName = file.uri.pathSegments.last;

    setState(() {
      _isRecording = false;
      _isPaused = false;
      _recordedFilePath = path;
    });

    await widget.onAnalyse(_promptText, path, fileName, 'audio/m4a', _elapsed.inSeconds);
  }

  Future<void> _pickAndAnalyse() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['m4a', 'wav', 'mp3', 'aac', 'ogg'],
      withData: false,
    );

    if (!mounted || result == null || result.files.isEmpty) {
      return;
    }

    final picked = result.files.single;
    final filePath = picked.path;
    if (filePath == null || filePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not access the selected file.')),
      );
      return;
    }

    await widget.onAnalyse(
      _promptText,
      filePath,
      picked.name,
      _guessMimeType(picked.extension),
      0,
    );
  }

  String _guessMimeType(String? extension) {
    return switch (extension?.toLowerCase()) {
      'wav' => 'audio/wav',
      'mp3' => 'audio/mpeg',
      'aac' => 'audio/aac',
      'ogg' => 'audio/ogg',
      _ => 'audio/m4a',
    };
  }

  String get _timerText {
    final minutes = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final circleColor =
        _isRecording ? const Color(0xFF6C63FF) : const Color(0xFF1A1A2E);

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              16 + MediaQuery.of(context).padding.bottom + 24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      ),
                      Expanded(
                        child: Text(
                          'New recording',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.tune_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('QUESTION', style: theme.textTheme.labelSmall),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  _promptText,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F2F9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  onPressed: _isRecording ? null : _shufflePrompt,
                                  icon: const Icon(Icons.shuffle_rounded),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const _FeedbackTag(
                            text: 'General HR',
                            backgroundColor: Color(0xFFEEF2FF),
                            foregroundColor: Color(0xFF6C63FF),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _WaveRing(
                    isActive: _isRecording,
                    child: GestureDetector(
                      onTap: _toggleMic,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          color: circleColor.withValues(alpha: _isRecording ? 1 : 0.88),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: circleColor.withValues(alpha: 0.18),
                              blurRadius: 28,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isPaused ? Icons.pause_rounded : Icons.mic_rounded,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isRecording ? _timerText : '00:00',
                    style: theme.textTheme.displayLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isRecording)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                        ),
                      Flexible(
                        child: Text(
                          _isRecording
                              ? (_isPaused ? 'Recording paused' : 'Recording...')
                              : (_recordedFilePath == null
                                    ? 'Tap the mic to start recording'
                                    : 'Ready to upload your recorded answer'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _isRecording
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF9CA3AF),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isRecording) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 52,
                          height: 52,
                          child: OutlinedButton(
                            onPressed: _toggleMic,
                            style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                            child: Icon(
                              _isPaused
                                  ? Icons.play_arrow_rounded
                                  : Icons.pause_rounded,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: FilledButton(
                              onPressed: widget.isSubmitting ? null : _stopAndAnalyseRecording,
                              child: widget.isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Stop and analyse'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 52,
                          height: 52,
                          child: OutlinedButton(
                            onPressed: _cancelRecording,
                            style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                            child: const Icon(Icons.close_rounded),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: widget.isSubmitting ? null : _startRecording,
                        child: Text(
                          widget.isSubmitting ? 'Uploading...' : 'Start recording',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: widget.isSubmitting ? null : _pickAndAnalyse,
                        child: const Text('Choose audio file instead'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    _recordedFilePath == null
                        ? 'You can record directly in the app or choose an existing audio file from your device.'
                        : 'Last recorded answer is ready. You can re-record or upload another file if needed.',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: const [
                        _TipChip(label: 'Speak at 130-160 wpm'),
                        SizedBox(width: 8),
                        _TipChip(label: 'Pause between points'),
                        SizedBox(width: 8),
                        _TipChip(label: 'Avoid "um" and "like"'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WaveRing extends StatelessWidget {
  const _WaveRing({required this.isActive, required this.child});

  final bool isActive;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bars = List.generate(26, (index) {
      final height = isActive ? (12 + (index % 5) * 6).toDouble() : 10.0;
      return Transform.rotate(
        angle: (index / 26) * 6.28318,
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            width: 4,
            height: height,
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withValues(alpha:
                isActive ? 0.85 : 0.35,
              ),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      );
    });

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: 230,
        height: 230,
        child: Stack(alignment: Alignment.center, children: [...bars, child]),
      ),
    );
  }
}

class _TipChip extends StatelessWidget {
  const _TipChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FC),
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: const Color.fromRGBO(0, 0, 0, 0.08)),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}

class _FeedbackTag extends StatelessWidget {
  const _FeedbackTag({
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
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.24,
        ),
      ),
    );
  }
}
