import 'package:flutter/material.dart';
import '../services/queue_navigation.dart';
import '../services/queue_session_store.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final snapshot = QueueSessionStore.latestSnapshot;
    final credentials = QueueSessionStore.credentials;
    final hasTicket = snapshot != null || credentials != null;
    final queueLabel =
        snapshot?.status.queueLabel ?? credentials?.queueLabel ?? 'No ticket';
    final status = snapshot?.status.status ?? 'Not checked';
    final subtitle = snapshot == null
        ? 'Enter a ticket to load live status'
        : '${snapshot.status.waitTime} wait - ${_timeLabel(snapshot.fetchedAt)}';
    final isComplete = snapshot?.status.isDone ?? false;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: QAppBar(
        title: 'History',
        showBack: true,
        onBack: () => goBack(context),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('Ticket sessions'),
            const SizedBox(height: 8),
            if (hasTicket)
              _SessionCard(
                number: queueLabel,
                subtitle: subtitle,
                status: isComplete ? 'Served' : status,
                isServed: isComplete,
              )
            else
              const _EmptyHistoryCard(),
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

  String _timeLabel(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }
}

class _SessionCard extends StatelessWidget {
  final String number;
  final String subtitle;
  final String status;
  final bool isServed;

  const _SessionCard({
    required this.number,
    required this.subtitle,
    required this.status,
    required this.isServed,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: AppColors.white,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                number,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        QBadge(
          label: status,
          bg: isServed ? AppColors.greenLight : AppColors.purpleLight,
          fg: isServed ? AppColors.green : AppColors.purpleDark,
        ),
      ],
    ),
  );
}

class _EmptyHistoryCard extends StatelessWidget {
  const _EmptyHistoryCard();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: AppColors.white,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Text(
      'No ticket session loaded on this device yet.',
      style: TextStyle(fontSize: 10, color: AppColors.textMuted),
    ),
  );
}
