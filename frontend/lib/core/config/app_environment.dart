import 'dart:io';

class AppEnvironment {
  // TODO: Update this IP when your computer's network changes.
  // Run `ipconfig` (Windows) or `ifconfig` (Mac/Linux) to find it.
  static const _lanIp = '10.101.123.83';

  static String get baseUrl {
    // Allow build-time override:
    // flutter run --dart-define=VOICEIQ_API_BASE_URL=http://your-ip:8080
    const configuredUrl = String.fromEnvironment('VOICEIQ_API_BASE_URL');
    if (configuredUrl.isNotEmpty) {
      return configuredUrl;
    }

    if (Platform.isAndroid) {
      // Real device: use your computer's LAN IP.
      // Emulator: use 10.0.2.2 (maps to host localhost).
      return 'http://$_lanIp:8000';
    }
    return 'http://localhost:8000';
  }
}
