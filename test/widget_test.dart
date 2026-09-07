import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:queueflow_mobile/main.dart';

void main() {
  testWidgets('boots to student sign-in when no saved session exists', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(const {});

    await tester.pumpWidget(const QueueFlowApp());

    // Immediately after the first frame: the bootstrap loading screen,
    // while StudentSessionStore.restoreSession() checks for a saved token.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Let the async restore-session check resolve and navigate.
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    // Both sign-in paths plus the distinct sign-up route are offered.
    expect(find.text('Log in with Face'), findsOneWidget);
    expect(find.text('Sign in with Gbox'), findsOneWidget);
    expect(find.text('Create an account'), findsOneWidget);
  });
}
