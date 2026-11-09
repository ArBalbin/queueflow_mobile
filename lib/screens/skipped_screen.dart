import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/queue_navigation.dart';
import '../services/queue_session_store.dart';
import '../services/student_session_store.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

/// Shown when staff mark the student as a no-show: their number was called,
/// they were not at the counter, and the line moved on. Without it the app
/// stayed on the waiting screen with no explanation.
class SkippedScreen extends StatefulWidget {
  const SkippedScreen({super.key});

  @override
  State<SkippedScreen> createState() => _SkippedScreenState();
}

class _SkippedScreenState extends State<SkippedScreen> {
  @override
  void initState() {
    super.initState();
    // The phone is likely in a pocket while the student waits: a buzz tells
    // them something changed.
    HapticFeedback.heavyImpact();
  }

  void _leave() {
    QueueSessionStore.clear();
    Navigator.pushReplacementNamed(
      context,
      StudentSessionStore.isLoggedIn ? '/student/home' : '/ticket/lookup',
    );
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = QueueSessionStore.latestSnapshot;
    final queueLabel =
        snapshot?.status.queueLabel ??
        QueueSessionStore.credentials?.queueLabel ??
        'Your number';
    final loggedIn = StudentSessionStore.isLoggedIn;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: QAppBar(
        title: 'My Queue Status',
        showBack: true,
        onBack: () => goBack(context),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.amberLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_off_rounded,
                  color: AppColors.amberBright,
                  size: 34,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Your number was skipped',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Staff marked you as not present when your number was called, '
                'so the line moved on.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.45),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$queueLabel is no longer active.',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      loggedIn
                          ? 'Still need the cashier? Step away from the camera for a few '
                              'seconds, then tap Join the Queue to get a new number.'
                          : 'Still need the cashier? Take a new ticket at the kiosk.',
                      style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                label: loggedIn ? 'Back to my dashboard' : 'Done',
                bg: AppColors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                fontSize: 14,
                onTap: _leave,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: QBottomNavBar(
        currentIndex: 0,
        onTap: (i) {
          QueueSessionStore.clear();
          Navigator.pushReplacementNamed(context, routeForBottomNavIndex(i));
        },
      ),
    );
  }
}
