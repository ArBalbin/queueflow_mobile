import 'package:flutter/material.dart';
import '../services/queue_navigation.dart';
import '../services/queue_session_store.dart';
import '../services/student_session_store.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final studentProfile = StudentSessionStore.profile;
    final isStudent = StudentSessionStore.isLoggedIn && studentProfile != null;

    final credentials = QueueSessionStore.credentials;
    final snapshot = QueueSessionStore.latestSnapshot;
    final queueLabel =
        snapshot?.status.queueLabel ??
        credentials?.queueLabel ??
        'No active queue';
    final tokenLabel = credentials == null
        ? 'Token: not loaded'
        : 'Token: ${credentials.maskedToken}';
    final statusLabel = snapshot?.status.status ?? 'Not checked';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: QAppBar(
        title: 'Profile',
        showBack: true,
        onBack: () => goBack(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.purpleLight,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'QF',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.purpleDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isStudent && studentProfile.fullName?.isNotEmpty == true
                            ? studentProfile.fullName!
                            : (isStudent ? 'Student' : 'QueuEx Guest'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isStudent
                            ? 'ID: ${studentProfile.schoolId}'
                            : 'Ticket holder (not signed in)',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const SectionLabel('My active token'),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current queue',
                    style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    queueLabel,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.purpleDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tokenLabel,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textLight,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const SectionLabel('Settings'),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _SettingRow(
                    label: 'Ticket status',
                    value: statusLabel,
                    valueColor: AppColors.green,
                  ),
                  const Divider(height: 1, color: Color(0xFFF0F0F4)),
                  const _SettingRow(label: 'Language', value: 'English'),
                  const Divider(height: 1, color: Color(0xFFF0F0F4)),
                  _SettingRow(
                    label: isStudent ? 'Log out of my account' : 'Clear ticket',
                    labelColor: AppColors.red,
                    onTap: () async {
                      QueueSessionStore.clear();
                      if (isStudent) {
                        await StudentSessionStore.logout();
                        if (!context.mounted) return;
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/student/login',
                          (route) => false,
                        );
                        return;
                      }
                      if (!context.mounted) return;
                      Navigator.pushReplacementNamed(context, '/ticket/lookup');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: QBottomNavBar(
        currentIndex: 2,
        onTap: (i) {
          if (i != 2) {
            Navigator.pushReplacementNamed(context, routeForBottomNavIndex(i));
          }
        },
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final String? value;
  final Color? labelColor;
  final Color? valueColor;
  final VoidCallback? onTap;

  const _SettingRow({
    required this.label,
    this.value,
    this.labelColor,
    this.valueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: labelColor ?? AppColors.dark),
          ),
          if (value != null)
            Text(
              value!,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textMuted,
              ),
            ),
        ],
      ),
    ),
  );
}
