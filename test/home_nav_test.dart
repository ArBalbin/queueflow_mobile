import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:queueflow_mobile/screens/student_home_screen.dart';

void main() {
  Widget app() => MaterialApp(
        home: const StudentHomeScreen(),
        routes: {
          '/history': (_) => const Scaffold(body: Text('history page')),
          '/profile': (_) => const Scaffold(body: Text('profile page')),
          '/help': (_) => const Scaffold(body: Text('help page')),
        },
      );

  Future<void> disposeHome(WidgetTester tester) async {
    // Unmount the dashboard so its poll timer is cancelled, then let any
    // request timeouts it started run out.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 1));
  }

  testWidgets('dashboard shows the bottom navigation before joining', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump();

    expect(find.text('My Queue'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Help'), findsOneWidget);

    await disposeHome(tester);
  });

  for (final (tab, page) in [
    ('History', 'history page'),
    ('Profile', 'profile page'),
    ('Help', 'help page'),
  ]) {
    testWidgets('dashboard $tab tab opens its screen', (tester) async {
      await tester.pumpWidget(app());
      await tester.pump();

      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();

      expect(find.text(page), findsOneWidget);
      await disposeHome(tester);
    });
  }
}
