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
            opacity: 0.15,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  QueueNumberCard(
                    number: queueDigits,
                    label: 'Your Number',
                    bg: AppColors.dark,
                    numColor: const Color(0xFF9FE1CB),
                    badge: const QBadge(
                      label: 'Ended',
                      bg: AppColors.amberLight,
                      fg: AppColors.amberText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: const [
                      Expanded(child: StatTile(value: '0', label: 'Ahead')),
                      SizedBox(width: 8),
                      Expanded(child: StatTile(value: '0', label: 'Est. min')),
                      SizedBox(width: 8),
                      Expanded(child: StatTile(value: '-', label: 'Counters')),
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
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 20,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderMid,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.amberLight,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.amberBright.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.amberBright,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your session has ended',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your transaction is complete. Kindly vacate the queue area to allow the next person to be served.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$queueLabel is no longer active.',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.dark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: "Got it, I'm leaving",
                    bg: AppColors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    fontSize: 14,
                    onTap: () {
                      QueueSessionStore.clear();
                      Navigator.pushReplacementNamed(
                        context,
                        StudentSessionStore.isLoggedIn
                            ? '/student/home'
                            : '/ticket/lookup',
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  PrimaryButton(
                    label: 'View my summary',
                    outlined: true,
                    borderColor: AppColors.borderMid,
                    fg: AppColors.dark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    fontSize: 14,
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