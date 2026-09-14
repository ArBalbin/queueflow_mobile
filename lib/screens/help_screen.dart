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
        title: 'Help & Support',
        showBack: true,
        onBack: () => goBack(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.greenDark, Color(0xFF1B4D3E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x10000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Need guidance?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Review our quick guidelines below to ensure a smooth queue experience.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SectionLabel('How it works'),
            const SizedBox(height: 12),
            const _HelpCard(
              iconBg: AppColors.greenLight,
              iconColor: AppColors.greenDark,
              icon: Icons.access_time_rounded,
              title: 'Camera-confirmed entry',
              body:
                  'Get your ticket from the kiosk, then hold it up to the '
                  'camera with your face visible. Once both are confirmed, '
                  'your real kiosk number shows up here automatically.',
            ),
            const SizedBox(height: 12),
            const _HelpCard(
              iconBg: AppColors.greenLight,
              iconColor: AppColors.green,
              icon: Icons.check_box_rounded,
              title: 'Check your status',
              body:
                  'Use your queue number and token to track your position anytime.',
            ),
            const SizedBox(height: 12),
            const _HelpCard(
              iconBg: AppColors.amberLight,
              iconColor: AppColors.amberBright,
              icon: Icons.timer_rounded,
              title: 'No-show policy',
              body:
                  'Return before the no-show countdown ends or your number may be skipped.',
            ),
            const SizedBox(height: 12),
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
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.white,
      border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(
          color: Color(0x06000000),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                body,
                style: const TextStyle(
                  fontSize: 13,
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
