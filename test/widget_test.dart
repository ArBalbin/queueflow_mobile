import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:queueflow_mobile/main.dart';
import 'package:queueflow_mobile/services/api_config.dart';

void main() {
  testWidgets('boots to student sign-in when no saved session exists', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(const {});

    await tester.pumpWidget(const QueueFlowApp());
    // The bootstrap screen checks for a saved session and, finding none,
    // replaces itself with the sign-in screen.
    await tester.pumpAndSettle();

    // Both sign-in paths, the separate sign-up route, and the guest path for
    // a printed kiosk ticket are all offered.
    expect(find.text('Log in with Face'), findsOneWidget);
    expect(find.text('Sign in with Gbox'), findsOneWidget);
    expect(find.text('New here?'), findsOneWidget);
    expect(find.text('Create an account'), findsOneWidget);
  });

  test('connects to the deployed backend, not localhost, by default', () {
    // Regression: a debug default once pointed release builds at localhost,
    // so the installed app could not reach the server at all.
    expect(ApiConfig.baseUrl, ApiConfig.cloudBaseUrl);
    expect(ApiConfig.baseUrl, startsWith('https://'));
    expect(ApiConfig.baseUrl, isNot(contains('localhost')));
    expect(ApiConfig.baseUrl, isNot(contains('127.0.0.1')));
  });
}
