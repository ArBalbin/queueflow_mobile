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

    final displayName = isStudent && studentProfile.fullName?.isNotEmpty == true
        ? studentProfile.fullName!
        : (isStudent ? 'Student' : 'QueuEx Guest');
    
    final displaySubtitle = isStudent
        ? 'ID: ${studentProfile.schoolId}'
        : 'Ticket holder (not signed in)';

    final initials = displayName.isNotEmpty
        ? displayName.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'Q';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          // Modernized immersive header banner with gradient
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.greenDark, Color(0xFF1B4D3E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => goBack(context),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                            padding: const EdgeInsets.all(10),
                          ),
                        ),
                        const Text(
                          'Profile & Settings',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initials,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.greenDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  displaySubtitle,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('My active token'),
                  const SizedBox(height: 10),
                  Container(
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
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.greenLight,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.confirmation_number_outlined,
                            color: AppColors.greenDark,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Current queue', style: AppText.caption),
                              const SizedBox(height: 3),
                              Text(
                                queueLabel,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.greenDark,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tokenLabel,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textLight,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SectionLabel('Preferences & Status'),
                  const SizedBox(height: 10),
                  Container(
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
                    child: Column(
                      children: [
                        _SettingRow(
                          icon: Icons.info_outline_rounded,
                          label: 'Ticket status',
                          value: statusLabel,
                          valueColor: AppColors.green,
                        ),
                        Divider(height: 1, color: AppColors.border.withValues(alpha: 0.4), indent: 16, endIndent: 16),
                        const _SettingRow(
                          icon: Icons.language_rounded,
                          label: 'Language',
                          value: 'English',
                        ),
                        Divider(height: 1, color: AppColors.border.withValues(alpha: 0.4), indent: 16, endIndent: 16),
                        _SettingRow(
                          icon: isStudent ? Icons.logout_rounded : Icons.clear_all_rounded,
                          label: isStudent ? 'Log out of my account' : 'Clear active ticket',
                          labelColor: AppColors.red,
                          iconColor: AppColors.red,
                          showChevron: false,
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
          ),
        ],
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
  final IconData icon;
  final String label;
  final String? value;
  final Color? labelColor;
  final Color? valueColor;
  final Color? iconColor;
  final bool showChevron;
  final VoidCallback? onTap;

  const _SettingRow({
    required this.icon,
    required this.label,
    this.value,
    this.labelColor,
    this.valueColor,
    this.iconColor,
    this.showChevron = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: iconColor ?? AppColors.textMuted,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: labelColor ?? AppColors.dark,
                  ),
                ),
              ),
              if (value != null) ...[
                Text(
                  value!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: valueColor ?? AppColors.textMuted,
                  ),
                ),
              ],
              if (showChevron) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: AppColors.textLight,
                ),
              ],
            ],
          ),
        ),
      );
}