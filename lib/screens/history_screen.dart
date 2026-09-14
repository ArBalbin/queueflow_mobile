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
        snapshot?.status.queueLabel ?? credentials?.queueLabel ?? '—';
    final isComplete = snapshot?.status.isDone ?? false;
    final statusLabel = isComplete
        ? 'Served'
        : (snapshot?.status.status ?? 'Not checked yet');

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: QAppBar(
        title: 'History',
        showBack: true,
        onBack: () => goBack(context),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('Your ticket'),
            const SizedBox(height: 10),
            if (hasTicket)
              _TicketStub(
                number: queueLabel,
                statusLabel: statusLabel,
                isServed: isComplete,
                waitTime: snapshot?.status.waitTime,
                fetchedAt: snapshot?.fetchedAt,
              )
            else
              const _EmptyStub(),
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
}

/// A queue ticket rendered like a physical stub: the number sits above a
/// tear-line, status and timing sit below it — instead of a generic
/// content-row-plus-badge card.
class _TicketStub extends StatelessWidget {
  final String number;
  final String statusLabel;
  final bool isServed;
  final String? waitTime;
  final DateTime? fetchedAt;

  const _TicketStub({
    required this.number,
    required this.statusLabel,
    required this.isServed,
    required this.waitTime,
    required this.fetchedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Queue number', style: AppText.caption),
                    const SizedBox(height: 4),
                    Text(
                      number,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                        color: AppColors.dark,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
                QBadge(
                  label: statusLabel,
                  bg: isServed ? AppColors.greenLight : AppColors.amberLight,
                  fg: isServed ? AppColors.green : AppColors.amberBright,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: _DashedLine(color: AppColors.border),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  waitTime != null
                      ? '$waitTime wait'
                      : 'Live status not loaded',
                  style: AppText.bodyMuted,
                ),
                if (fetchedAt != null)
                  Text(
                    'Checked ${_timeLabel(fetchedAt!)}',
                    style: AppText.caption,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeLabel(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'pm' : 'am';
    return '$hour:$minute$suffix';
  }
}

class _EmptyStub extends StatelessWidget {
  const _EmptyStub();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'No ticket yet',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 10),
          _DashedLine(color: AppColors.border),
          const SizedBox(height: 10),
          const Text(
            'Enter a ticket number to see its status here.',
            style: AppText.bodyMuted,
          ),
        ],
      ),
    );
  }
}

/// A lightweight horizontal dashed rule — the tear-line motif shared by the
/// filled and empty ticket states.
class _DashedLine extends StatelessWidget {
  final Color color;
  const _DashedLine({required this.color});

  @override
  Widget build(BuildContext context) {
    const dashWidth = 5.0;
    const dashGap = 4.0;
    return SizedBox(
      height: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final count = (constraints.maxWidth / (dashWidth + dashGap)).floor();
          return Row(
            children: List.generate(
              count,
              (_) => Padding(
                padding: const EdgeInsets.only(right: dashGap),
                child: Container(width: dashWidth, height: 1, color: color),
              ),
            ),
          );
        },
      ),
    );
  }
}
