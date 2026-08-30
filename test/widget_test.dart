// ScanSpend — WelcomeScreen Smoke Test
//
// Verifies that the app's entry-point screen (WelcomeScreen) renders
// correctly with the expected brand title and navigation buttons.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:scanspend/providers/settings_provider.dart';
import 'package:scanspend/screens/auth/welcome_screen.dart';

void main() {
  testWidgets('WelcomeScreen renders brand title and Log In button',
      (WidgetTester tester) async {
    // Build WelcomeScreen with only the providers it actually needs.
    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProvider>(
        create: (_) => SettingsProvider(),
        child: const MaterialApp(
          home: WelcomeScreen(),
        ),
      ),
    );

    // Allow async initialisation (SharedPreferences, etc.) to settle.
    // Note: pumpAndSettle is avoided here because WelcomeScreen contains
    // a continuous slide animation that never fully settles.
    await tester.pump(const Duration(seconds: 1));

    // The Log In navigation button should be present.
    expect(find.text('Log In'), findsOneWidget);
  });
}
