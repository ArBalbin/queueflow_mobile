import 'package:flutter/material.dart';

import '../models/queue_models.dart';
import '../services/long_wait.dart';
import '../theme/app_theme.dart';
import 'live_wait.dart';

/// Which number each cashier window is serving right now, and for how long,
/// e.g. "Window 1  Q5000  at the window 3:12". The student's own number is
/// marked when it is called. A window taking longer than the average service
/// time is marked, since that is what moves everyone's estimate later.
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
          if (prediction.avgServiceSeconds > 0) ...[
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 15,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Average service time',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                ),
                Text(
                  formatClock(prediction.avgServiceSeconds),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(NowServing entry) {
    final mine = myQueueNumber != null && entry.queueNumber == myQueueNumber;
    final seconds = entry.servingSeconds;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Window ${entry.counterNumber}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
                if (seconds != null)
                  Row(
                    children: [
                      Text(
                        entry.runningLong
                            ? 'taking longer than usual · '
                            : 'at the window · ',
                        style: TextStyle(
                          fontSize: 11,
                          color: entry.runningLong
                              ? AppColors.amberText
                              : AppColors.textMuted,
                        ),
                      ),
                      LiveCountUp(
                        seconds: seconds,
                        anchor: prediction.receivedAt,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: entry.runningLong
                              ? AppColors.amberText
                              : AppColors.textMuted,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
              ],
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
