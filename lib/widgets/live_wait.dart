import 'dart:async';

import 'package:flutter/material.dart';

import '../models/queue_models.dart';
import '../theme/app_theme.dart';

/// A number of seconds as a clock: "3:05", or "1:02:05" past an hour.
String formatClock(int seconds) {
  final s = seconds < 0 ? 0 : seconds;
  final hours = s ~/ 3600;
  final minutes = (s % 3600) ~/ 60;
  final rest = (s % 60).toString().padLeft(2, '0');
  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:$rest';
  }
  return '$minutes:$rest';
}

/// Rebuilds once a second, so a time worked out by the server can be counted
/// on the phone between requests. Each new request replaces the anchor.
class Ticking extends StatefulWidget {
  final Widget Function(BuildContext context, int secondsSinceAnchor) builder;
  final DateTime anchor;
  const Ticking({super.key, required this.anchor, required this.builder});

  @override
  State<Ticking> createState() => _TickingState();
}

class _TickingState extends State<Ticking> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final since = DateTime.now().difference(widget.anchor).inSeconds;
    return widget.builder(context, since < 0 ? 0 : since);
  }
}

/// The wait counting down: "3:05", "3:04", ... The server works it out again
/// every few seconds from the line as it is then, and the count restarts from
/// that new figure, so it moves later when a window runs long.
class LiveCountdown extends StatelessWidget {
  final int seconds;
  final DateTime anchor;
  final TextStyle? style;
  final String zeroText;

  /// False while the line is paused (nobody at a window): the time is shown
  /// as the server gave it and does not count down.
  final bool running;

  const LiveCountdown({
    super.key,
    required this.seconds,
    required this.anchor,
    this.style,
    this.zeroText = '0:00',
    this.running = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!running) {
      return Text(
        seconds <= 0 ? zeroText : formatClock(seconds),
        maxLines: 1,
        style: style,
      );
    }
    return Ticking(
      anchor: anchor,
      builder: (context, since) {
        final left = seconds - since;
        return Text(
          left <= 0 ? zeroText : formatClock(left),
          maxLines: 1,
          style: style,
        );
      },
    );
  }
}

/// How long the student at a window has been there, counting up.
class LiveCountUp extends StatelessWidget {
  final int seconds;
  final DateTime anchor;
  final TextStyle? style;

  const LiveCountUp({
    super.key,
    required this.seconds,
    required this.anchor,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Ticking(
      anchor: anchor,
      builder: (context, since) =>
          Text(formatClock(seconds + since), maxLines: 1, style: style),
    );
  }
}

/// What an estimate was worked out from, in words a student can check:
/// "2 ahead of you · 1 window calling · about 1:52 each".
String restsOn({
  required int ahead,
  required int windowsCalling,
  required int avgSeconds,
  String aheadLabel = 'in line',
}) {
  final people = '$ahead $aheadLabel';
  final windows = windowsCalling <= 0
      ? 'no window calling yet (worked out for 1)'
      : '$windowsCalling window${windowsCalling == 1 ? '' : 's'} calling';
  final each = avgSeconds > 0 ? ' · about ${formatClock(avgSeconds)} each' : '';
  return '$people · $windows$each';
}

/// Said instead of counting down while nobody is at a window.
class PausedNote extends StatelessWidget {
  const PausedNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.pause_circle_outline_rounded,
            size: 16,
            color: AppColors.textMuted,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Paused: no one is at a window, so this time does not count down '
              'until a window calls the next number.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Estimated time of service": the clock time this student's turn is
/// expected, the wait counting down to it, the average service time it rests
/// on, and why it moved when a window is running long.
class ServiceTimeCard extends StatelessWidget {
  final QueueEstimate estimate;
  final DateTime anchor;

  const ServiceTimeCard({
    super.key,
    required this.estimate,
    required this.anchor,
  });

  @override
  Widget build(BuildContext context) {
    final avg = estimate.avgServiceSeconds;
    final basis = estimate.avgServiceBasis;
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
              Icon(Icons.schedule_rounded, size: 16, color: AppColors.green),
              SizedBox(width: 6),
              Text(
                'Estimated time of service',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    estimate.estimatedServiceStartLabel.isEmpty
                        ? '—'
                        : estimate.estimatedServiceStartLabel,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.greenDark,
                      height: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  LiveCountdown(
                    seconds: estimate.estimatedWaitSeconds,
                    anchor: anchor,
                    running: estimate.lineMoving,
                    zeroText: 'any moment',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const Text(
                    'min:sec to go',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                avg > 0 ? formatClock(avg) : '—',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          if (basis.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 21, top: 2),
              child: Text(
                basis.startsWith('last')
                    ? 'per student, from the $basis'
                    : 'per student, the usual pace until services are timed',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          const SizedBox(height: 10),
          Text(
            restsOn(
              ahead: estimate.peopleAhead,
              windowsCalling: estimate.windowsCalling,
              avgSeconds: avg,
              aheadLabel: 'ahead of you',
            ),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.dark,
              height: 1.4,
            ),
          ),
          if (!estimate.lineMoving) ...[
            const SizedBox(height: 8),
            const PausedNote(),
          ],
          if (estimate.adjustmentNote.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.amberLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                estimate.adjustmentNote,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.amberText,
                  height: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          const Text(
            'Worked out again every few seconds from who is at each window, '
            'for how long, and how many are ahead of you.',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
