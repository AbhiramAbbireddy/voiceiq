import 'package:flutter/material.dart';

import 'app_controller.dart';
import '../features/onboarding/presentation/launch_page.dart';
import '../features/home/presentation/home_page.dart';
import 'theme.dart';

class VoiceIqApp extends StatefulWidget {
  const VoiceIqApp({super.key});

  @override
  State<VoiceIqApp> createState() => _VoiceIqAppState();
}

class _VoiceIqAppState extends State<VoiceIqApp> {
  late final VoiceIqAppController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VoiceIqAppController();
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return MaterialApp(
          title: 'VoiceIQ',
          debugShowCheckedModeBanner: false,
          theme: buildVoiceIqTheme(),
          darkTheme: buildVoiceIqDarkTheme(),
          themeMode: ThemeMode.system,
          home: _controller.isBootstrapping
              ? const _BootPage()
              : _controller.isAuthenticated
              ? HomePage(controller: _controller)
              : LaunchPage(controller: _controller),
        );
      },
    );
  }
}

class _BootPage extends StatelessWidget {
  const _BootPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
