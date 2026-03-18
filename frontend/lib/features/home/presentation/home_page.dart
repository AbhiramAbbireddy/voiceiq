import 'package:flutter/material.dart';

import '../../../app/app_controller.dart';
import '../../../core/widgets/voiceiq_bottom_nav.dart';
import '../../analysis/presentation/analysis_loading_page.dart';
import '../../analysis/presentation/feedback_report_page.dart';
import '../../mock_interview/presentation/mock_interview_page.dart';
import '../../profile/presentation/profile_page.dart';
import '../../progress/presentation/progress_page.dart';
import '../../record/presentation/record_page.dart';
import 'dashboard_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.controller});

  final VoiceIqAppController controller;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  bool _isSubmittingRecording = false;

  void _openPage(Widget page) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  Future<void> _handleAnalyse(
    String promptText,
    String filePath,
    String fileName,
    String mimeType,
    int durationSeconds,
  ) async {
    setState(() => _isSubmittingRecording = true);
    try {
      final sessionId = await widget.controller.submitAudioAnalysis(
        promptText: promptText,
        filePath: filePath,
        durationSeconds: durationSeconds,
      );
      if (!mounted) {
        return;
      }
      _openPage(
        AnalysisLoadingPage(
          controller: widget.controller,
          sessionId: sessionId,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmittingRecording = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(
        controller: widget.controller,
        onOpenRecord: () => setState(() => _currentIndex = 1),
        onOpenProgress: () => setState(() => _currentIndex = 2),
        onOpenProfile: () => setState(() => _currentIndex = 3),
        onOpenLibrary: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Practice library is coming next.')),
          );
        },
        onOpenReport: () {
          final report = widget.controller.latestReport;
          if (report == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Complete one analysis to view a real report.')),
            );
            return;
          }
          _openPage(FeedbackReportPage(report: report));
        },
        onOpenMockInterview: () => _openPage(const MockInterviewPage()),
      ),
      RecordPage(
        isSubmitting: _isSubmittingRecording,
        onAnalyse: _handleAnalyse,
      ),
      ProgressPage(controller: widget.controller),
      ProfilePage(controller: widget.controller),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: VoiceIqBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
