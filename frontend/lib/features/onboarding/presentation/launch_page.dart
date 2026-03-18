import 'package:flutter/material.dart';
import 'dart:async';

import '../../../app/app_controller.dart';

class LaunchPage extends StatefulWidget {
  const LaunchPage({super.key, required this.controller});

  final VoiceIqAppController controller;

  @override
  State<LaunchPage> createState() => _LaunchPageState();
}

class _LaunchPageState extends State<LaunchPage> {
  final _pageController = PageController();
  int _pageIndex = 0;
  bool _showAuth = false;
  bool _isSignup = true;
  Timer? _autoSwipeTimer;

  @override
  void initState() {
    super.initState();
    _startAutoSwipe();
  }

  void _startAutoSwipe() {
    _autoSwipeTimer?.cancel();
    _autoSwipeTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _showAuth) return;
      if (_pageIndex < 2) {
        _pageController.animateToPage(
          _pageIndex + 1,
          duration: const Duration(milliseconds: 520),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoSwipeTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: _showAuth
            ? AuthPage(
                key: const ValueKey('auth'),
                isSignup: _isSignup,
                controller: widget.controller,
                onToggleMode: () => setState(() => _isSignup = !_isSignup),
              )
            : Stack(
                key: const ValueKey('onboarding'),
                children: [
                  PageView(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => _pageIndex = index),
                    children: [
                      OnboardingSlide(
                        backgroundColor: const Color(0xFF1A1A2E),
                        waveformDark: true,
                        title: 'Speak with confidence.',
                        subtitle:
                            'Record your answers. Get AI feedback. Improve every session.',
                        button: FilledButton(
                          onPressed: () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOut,
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF),
                          ),
                          child: const Text('Get started'),
                        ),
                      ),
                      OnboardingSlide(
                        backgroundColor: Colors.white,
                        reportMock: true,
                        title: 'Know exactly where to improve',
                        subtitle:
                            'AI detects pace, tone, filler words, and confidence - then tells you how to fix each one.',
                        darkText: true,
                        button: FilledButton(
                          onPressed: () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOut,
                          ),
                          child: const Text('Continue'),
                        ),
                      ),
                      OnboardingSlide(
                        backgroundColor: const Color(0xFFF8F8FC),
                        phoneMock: true,
                        title: 'Practice with an AI interviewer',
                        subtitle:
                            'Real questions. Real-time responses. You improve before the actual interview.',
                        darkText: true,
                        button: Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed: () => setState(() {
                                  _showAuth = true;
                                  _isSignup = true;
                                }),
                                child: const Text('Sign up free'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => setState(() {
                                  _showAuth = true;
                                  _isSignup = false;
                                }),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF1A1A2E),
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(
                                    color: Color(0xFF1A1A2E),
                                  ),
                                ),
                                child: const Text('Log in'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 118,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        final active = index == _pageIndex;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: active ? 20 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: active
                                ? const Color(0xFF6C63FF)
                                : const Color(0xFFD1D5DB),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({
    super.key,
    required this.backgroundColor,
    required this.title,
    required this.subtitle,
    required this.button,
    this.waveformDark = false,
    this.reportMock = false,
    this.phoneMock = false,
    this.darkText = false,
  });

  final Color backgroundColor;
  final String title;
  final String subtitle;
  final Widget button;
  final bool waveformDark;
  final bool reportMock;
  final bool phoneMock;
  final bool darkText;

  @override
  Widget build(BuildContext context) {
    final titleColor = darkText ? const Color(0xFF1A1A2E) : Colors.white;
    final subtitleColor =
        darkText ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);

    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.fromLTRB(24, 84, 24, 40),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: waveformDark
                  ? const HeroWaveform()
                  : reportMock
                      ? const ReportMockCard()
                      : const PhoneMockCard(),
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: titleColor,
              fontSize: darkText ? 24 : 28,
              height: 1.18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: subtitleColor,
              fontSize: darkText ? 14 : 16,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 32),
          button,
        ],
      ),
    );
  }
}

class AuthPage extends StatelessWidget {
  const AuthPage({
    super.key,
    required this.isSignup,
    required this.controller,
    required this.onToggleMode,
  });

  final bool isSignup;
  final VoiceIqAppController controller;
  final VoidCallback onToggleMode;

  @override
  Widget build(BuildContext context) {
    return _AuthForm(
      isSignup: isSignup,
      controller: controller,
      onToggleMode: onToggleMode,
    );
  }
}

class _AuthForm extends StatefulWidget {
  const _AuthForm({
    required this.isSignup,
    required this.controller,
    required this.onToggleMode,
  });

  final bool isSignup;
  final VoiceIqAppController controller;
  final VoidCallback onToggleMode;

  @override
  State<_AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<_AuthForm> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  late final TextEditingController _targetRoleController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _targetRoleController = TextEditingController(text: 'Software Engineer');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _targetRoleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorMessage = null);

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Email and password are required.');
      return;
    }

    if (widget.isSignup) {
      if (_fullNameController.text.trim().isEmpty) {
        setState(() => _errorMessage = 'Full name is required.');
        return;
      }
      if (_targetRoleController.text.trim().isEmpty) {
        setState(() => _errorMessage = 'Target role is required.');
        return;
      }
      if (password != _confirmPasswordController.text) {
        setState(() => _errorMessage = 'Passwords do not match.');
        return;
      }
    }

    try {
      if (widget.isSignup) {
        await widget.controller.signUp(
          fullName: _fullNameController.text.trim(),
          email: email,
          password: password,
          targetRole: _targetRoleController.text.trim(),
        );
      } else {
        await widget.controller.login(email: email, password: password);
      }
    } catch (error) {
      setState(() => _errorMessage = error.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBusy = widget.controller.isAuthBusy;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1A) : Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: AppWordmark()),
              const SizedBox(height: 32),
              Container(
                height: 52,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF171728) : const Color(0xFFF8F8FC),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Stack(
                  children: [
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeInOut,
                      alignment: widget.isSignup
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: FractionallySizedBox(
                        widthFactor: 0.5,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF232338) : Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: const [
                              BoxShadow(
                                color: Color.fromRGBO(0, 0, 0, 0.08),
                                blurRadius: 3,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _AuthTab(
                            label: 'Sign up',
                            active: widget.isSignup,
                            onTap: widget.isSignup ? null : widget.onToggleMode,
                          ),
                        ),
                        Expanded(
                          child: _AuthTab(
                            label: 'Log in',
                            active: !widget.isSignup,
                            onTap: widget.isSignup ? widget.onToggleMode : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (widget.isSignup) ...[
                TextField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(labelText: 'Full name'),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email address'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              if (widget.isSignup) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Confirm password'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _targetRoleController,
                  decoration: const InputDecoration(labelText: 'Target role'),
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Color(0xFFB91C1C),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'By signing up you agree to our Terms and Privacy Policy',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF9CA3AF),
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isBusy ? null : _submit,
                  child: isBusy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.isSignup ? 'Create account' : 'Log in'),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: const [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'or continue with',
                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                    ),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SocialButton(
                      label: 'Google',
                      icon: Icons.g_mobiledata_rounded,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: SocialButton(
                      label: 'Apple',
                      icon: Icons.apple_rounded,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthTab extends StatelessWidget {
  const _AuthTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class AppWordmark extends StatelessWidget {
  const AppWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Text.rich(
      TextSpan(
        style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        children: [
          const TextSpan(text: 'Voice'),
          const TextSpan(text: 'IQ', style: TextStyle(color: Color(0xFF6C63FF))),
        ],
      ),
    );
  }
}

class SocialButton extends StatelessWidget {
  const SocialButton({
    super.key,
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        backgroundColor: isDark ? const Color(0xFF171728) : const Color(0xFFF8F8FC),
        foregroundColor: onSurface,
        side: BorderSide(
          color: isDark
              ? const Color.fromRGBO(255, 255, 255, 0.08)
              : const Color.fromRGBO(0, 0, 0, 0.08),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: onSurface),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class HeroWaveform extends StatelessWidget {
  const HeroWaveform({super.key});

  @override
  Widget build(BuildContext context) {
    final heights = List.generate(44, (index) => 28.0 + (index % 9) * 8.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = (constraints.maxWidth / 18).clamp(3.0, 5.0);
        final spacing = (constraints.maxWidth / 70).clamp(1.0, 2.0);
        return SizedBox(
          height: 220,
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(heights.length, (index) {
                return Container(
                  width: barWidth,
                  height: heights[index],
                  margin: EdgeInsets.symmetric(horizontal: spacing),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xFF6C63FF), Color(0xFFA78BFA)],
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

class ReportMockCard extends StatelessWidget {
  const ReportMockCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.08),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(
              value: 0.72,
              strokeWidth: 10,
              backgroundColor: Color(0xFFF3F4F6),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
            ),
          ),
          SizedBox(height: 12),
          Text('72', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
          SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _SmallTag(text: 'Too many fillers', color: Color(0xFFFFFBEB), textColor: Color(0xFFB45309)),
              _SmallTag(text: 'Good pace', color: Color(0xFFDCFCE7), textColor: Color(0xFF166534)),
              _SmallTag(text: 'Low confidence', color: Color(0xFFEEF2FF), textColor: Color(0xFF6C63FF)),
            ],
          ),
        ],
      ),
    );
  }
}

class PhoneMockCard extends StatelessWidget {
  const PhoneMockCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 340,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color.fromRGBO(0, 0, 0, 0.08)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8FC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Tell me about yourself...',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A2E),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mic_rounded, color: Colors.white),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _SmallTag extends StatelessWidget {
  const _SmallTag({
    required this.text,
    required this.color,
    required this.textColor,
  });

  final String text;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontSize: 12),
      ),
    );
  }
}
