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
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                color: AppColors.greenLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: Color(0xFF1D9E75),
                size: 36,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Service Complete',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$queueLabel has been served.\nThank you for your patience!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _SummaryRow(label: 'Queue number', value: queueLabel),
                  _SummaryRow(label: 'Total wait', value: waitTime),
                  _SummaryRow(label: 'Updated at', value: servedAt),
                  const _SummaryRow(
                    label: 'Counter',
                    value: 'Assigned by staff',
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Back to Home',
              onTap: () => Navigator.pushReplacementNamed(
                context,
                routeForCurrentQueue(),
              ),
            ),
          ],
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
  final String label;
  final String value;
  final bool isLast;
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.dark,
              ),
            ),
          ],
        ),
      ),
      if (!isLast) const Divider(height: 1, color: Color(0xFFF0F0F4)),
    ],
  );
}
