import 'package:flutter/material.dart';

import '../models/queue_models.dart';
import '../services/long_wait.dart';
import '../theme/app_theme.dart';

/// Which number each cashier window is serving right now, e.g.
/// "Window 1  Q5000". The student's own number is marked when it is called.
class NowServingCard extends StatelessWidget {
  final QueuePrediction prediction;
  final int? myQueueNumber;

  const NowServingCard({
    super.key,
    required this.prediction,
    this.myQueueNumber,
  });

  @override
  Widget build(BuildContext context) {
    final closedUntil = prediction.countersClosedUntil;
    final closed = closedUntil != null && closedUntil.isAfter(DateTime.now());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.campaign_rounded, size: 16, color: AppColors.green),
              SizedBox(width: 6),
              Text(
                'Now serving',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (closed)
            Text(
              'All windows are closed until ${formatClockTime(closedUntil)}. '
              'You can still get a number; the line moves once they reopen.',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.amberText,
                height: 1.4,
              ),
            )
          else if (prediction.nowServing.isEmpty)
            const Text(
              'No one is at a window right now.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            )
          else
            for (final entry in prediction.nowServing) _row(entry),
        ],
      ),
    );
  }

  Widget _row(NowServing entry) {
    final mine = myQueueNumber != null && entry.queueNumber == myQueueNumber;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Window ${entry.counterNumber}',
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ),
          Text(
            entry.queueLabel,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: mine ? AppColors.green : AppColors.dark,
            ),
          ),
          if (mine) ...[
            const SizedBox(width: 6),
            const Text(
              'you',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.green,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
