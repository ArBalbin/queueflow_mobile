import 'package:flutter/material.dart';
import '../services/queue_navigation.dart';
import '../services/queue_session_store.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class ServiceCompleteScreen extends StatelessWidget {
  const ServiceCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final snapshot = QueueSessionStore.latestSnapshot;
    final queueLabel =
        snapshot?.status.queueLabel ??
        QueueSessionStore.credentials?.queueLabel ??
        'your queue number';
    final waitTime = snapshot?.status.waitTime ?? '-';
    final servedAt = _timeLabel(snapshot?.fetchedAt);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: QAppBar(
        title: 'QueuEx',
        showBack: true,
        onBack: () => goBack(context),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.green.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.green,
                  size: 42,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Service Complete',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$queueLabel has been successfully served.\nThank you for your patience!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _SummaryRow(
                      icon: Icons.confirmation_number_outlined,
                      label: 'Queue number',
                      value: queueLabel,
                    ),
                    _SummaryRow(
                      icon: Icons.hourglass_bottom_rounded,
                      label: 'Total wait',
                      value: waitTime,
                    ),
                    _SummaryRow(
                      icon: Icons.access_time_rounded,
                      label: 'Updated at',
                      value: servedAt,
                    ),
                    _SummaryRow(
                      icon: Icons.storefront_rounded,
                      label: 'Counter',
                      value: 'Assigned by staff',
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                label: 'Back to Home',
                bg: AppColors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                fontSize: 14,
                onTap: () => Navigator.pushReplacementNamed(
                  context,
                  routeForCurrentQueue(),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: QBottomNavBar(
        currentIndex: 1,
        onTap: (i) {
          if (i != 1) {
            Navigator.pushReplacementNamed(context, routeForBottomNavIndex(i));
          }
        },
      ),
    );
  }

  String _timeLabel(DateTime? value) {
    if (value == null) return '-';
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.greenLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: AppColors.green),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
          ],
        ),
      ),
      if (!isLast)
        const Divider(height: 1, color: AppColors.border, thickness: 0.8),
    ],
  );
}
