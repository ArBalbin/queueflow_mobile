import 'package:flutter/material.dart';
import '../services/queue_navigation.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: QAppBar(
        title: 'Help',
        showBack: true,
        onBack: () => goBack(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('How it works'),
            const SizedBox(height: 8),
            const _HelpCard(
              iconBg: AppColors.purpleLight,
              iconColor: AppColors.purpleDark,
              icon: Icons.access_time_rounded,
              title: 'Camera-confirmed entry',
              body:
                  'Get your ticket from the kiosk, then hold it up to the '
                  'camera with your face visible. Once both are confirmed, '
                  'your real kiosk number shows up here automatically.',
            ),
            const SizedBox(height: 8),
            const _HelpCard(
              iconBg: AppColors.greenLight,
              iconColor: AppColors.green,
              icon: Icons.check_box_rounded,
              title: 'Check your status',
              body:
                  'Use your queue number and token to track your position anytime.',
            ),
            const SizedBox(height: 8),
            const _HelpCard(
              iconBg: AppColors.amberLight,
              iconColor: AppColors.amberBright,
              icon: Icons.timer_rounded,
              title: 'No-show policy',
              body:
                  'Return before the no-show countdown ends or your number may be skipped.',
            ),
            const SizedBox(height: 8),
            const _HelpCard(
              iconBg: AppColors.redLight,
              iconColor: AppColors.redDark,
              icon: Icons.info_rounded,
              title: 'Need assistance?',
              body:
                  'Approach any counter staff for help. Show your queue slip if needed.',
            ),
          ],
        ),
      ),
      bottomNavigationBar: QBottomNavBar(
        currentIndex: 3,
        onTap: (i) {
          if (i != 3) {
            Navigator.pushReplacementNamed(context, routeForBottomNavIndex(i));
          }
        },
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String title;
  final String body;
  const _HelpCard({
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.body,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: AppColors.white,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, color: iconColor, size: 14),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
