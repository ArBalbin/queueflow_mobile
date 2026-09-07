import 'package:flutter/material.dart';
import '../services/queue_navigation.dart';
import '../services/queue_session_store.dart';
import '../services/student_session_store.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class ExitNotificationScreen extends StatelessWidget {
  const ExitNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final snapshot = QueueSessionStore.latestSnapshot;
    final queueDigits =
        snapshot?.status.queueDigits ??
        QueueSessionStore.credentials?.queueDigits ??
        '---';
    final queueLabel =
        snapshot?.status.queueLabel ??
        QueueSessionStore.credentials?.queueLabel ??
        'Your queue number';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: QAppBar(
        title: 'My Queue Status',
        showBack: true,
        onBack: () => goBack(context),
      ),
      body: Stack(
        children: [
          Opacity(
            opacity: 0.2,
            child: Padding(
              padding: const EdgeInsets.all(11),
              child: Column(
                children: [
                  QueueNumberCard(
                    number: queueDigits,
                    label: 'Your Number',
                    bg: AppColors.dark,
                    numColor: const Color(0xFFA29EF0),
                    badge: const QBadge(
                      label: 'Waiting',
                      bg: AppColors.purpleLight,
                      fg: AppColors.purpleDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: const [
                      StatTile(value: '0', label: 'Ahead'),
                      SizedBox(width: 6),
                      StatTile(value: '0', label: 'Est. min'),
                      SizedBox(width: 6),
                      StatTile(value: '2', label: 'Counters'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(15, 16, 15, 20),
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(top: BorderSide(color: AppColors.borderMid)),
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDDDE8),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.purpleLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.purpleDark,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Your session has ended',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your transaction is now complete. Kindly vacate the queue area to allow the next person to be served.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF666666),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$queueLabel is no longer active.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  PrimaryButton(
                    label: "Got it, I'm leaving",
                    onTap: () {
                      QueueSessionStore.clear();
                      // A signed-in student goes back to their own dashboard;
                      // only a guest (tracking a printed ticket with no
                      // account) has nowhere to land but the lookup form.
                      Navigator.pushReplacementNamed(
                        context,
                        StudentSessionStore.isLoggedIn
                            ? '/student/home'
                            : '/ticket/lookup',
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  PrimaryButton(
                    label: 'View my summary',
                    outlined: true,
                    onTap: () => Navigator.pushReplacementNamed(
                      context,
                      '/queue/complete',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: QBottomNavBar(currentIndex: 0, onTap: (_) {}),
    );
  }
}
