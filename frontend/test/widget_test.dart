import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/app/app_controller.dart';
import 'package:frontend/features/onboarding/presentation/launch_page.dart';

void main() {
  testWidgets('VoiceIQ launches into onboarding flow', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: LaunchPage(controller: VoiceIqAppController())),
    );

    expect(find.text('Speak with confidence.'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });
}
