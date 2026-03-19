import 'dart:io';

import 'package:flutter/foundation.dart';

class AppEnvironment {
  // TODO: Update this IP when your computer's network changes.
  // Run `ipconfig` (Windows) or `ifconfig` (Mac/Linux) to find it.
  static const _lanIp = '10.101.123.83';
  static const _localPort = '9090';

  static String get baseUrl {
    // Allow build-time override:
    // flutter run --dart-define=VOICEIQ_API_BASE_URL=http://your-ip:9090
    // flutter build apk --release --dart-define=VOICEIQ_API_BASE_URL=https://api.your-domain.com
    const configuredUrl = String.fromEnvironment('VOICEIQ_API_BASE_URL');
    if (configuredUrl.isNotEmpty) {
      return configuredUrl;
    }

    if (kReleaseMode) {
      // Release builds should always pass a real hosted API URL via --dart-define.
      return 'https://api.voiceiq.app';
    }

    if (Platform.isAndroid) {
      // Real device: use your computer's LAN IP.
      // Emulator: use 10.0.2.2 (maps to host localhost).
      return 'http://$_lanIp:$_localPort';
    }
    return 'http://localhost:$_localPort';
  }
}
