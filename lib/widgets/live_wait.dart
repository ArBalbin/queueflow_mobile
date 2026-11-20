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

const _digits = [FontFeature.tabularFigures()];

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

/// The wait as a running clock: "3:05", "3:04", ... down to "0:00". The
/// server works it out again every few seconds from the line as it is then,
/// and the clock restarts from that figure, so it moves later when a window
/// runs long. While nobody is at a window ([running] false) the line is not
/// moving, and the clock holds the server's figure instead of counting.
class LiveCountdown extends StatelessWidget {
  final int seconds;
  final DateTime anchor;
  final TextStyle? style;
  final bool running;

  const LiveCountdown({
    super.key,
    required this.seconds,
    required this.anchor,
    this.style,
    this.running = true,
  });

  @override
  Widget build(BuildContext context) {
    final shown = style?.copyWith(fontFeatures: _digits);
    if (!running) {
      return Text(formatClock(seconds), maxLines: 1, style: shown);
    }
    return Ticking(
      anchor: anchor,
      builder: (context, since) =>
          Text(formatClock(seconds - since), maxLines: 1, style: shown),
    );
  }
}

/// A time counting up: how long someone has waited, or been at a window.
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
    final shown = style?.copyWith(fontFeatures: _digits);
    return Ticking(
      anchor: anchor,
      builder: (context, since) =>
          Text(formatClock(seconds + since), maxLines: 1, style: shown),
    );
  }
}

/// "Live" while someone is at a window and the clocks count; "Paused" while
/// nobody is, so a clock that holds still is not mistaken for a frozen app.
class LineStatusTag extends StatelessWidget {
  final bool moving;
  const LineStatusTag({super.key, required this.moving});

  @override
  Widget build(BuildContext context) {
    final color = moving ? AppColors.green : AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: moving ? AppColors.greenLight : AppColors.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 7, color: color),
          const SizedBox(width: 5),
          Text(
            moving ? 'Live' : 'Paused',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// The student's turn as a clock time, how long they have waited so far, and
/// the average service time the estimate rests on. The wait itself is the
/// running clock at the top of the screen.
class ServiceTimeCard extends StatelessWidget {
  final QueueEstimate estimate;
  final DateTime anchor;

  /// How long this student has been in line, when the server answered.
  final int waitedSeconds;

  const ServiceTimeCard({
    super.key,
    required this.estimate,
    required this.anchor,
    required this.waitedSeconds,
  });

  @override
  Widget build(BuildContext context) {
    const label = TextStyle(fontSize: 13, color: AppColors.textMuted);
    const value = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: AppColors.dark,
    );
    final avg = estimate.avgServiceSeconds;
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
          Row(
            children: [
              const Expanded(child: Text('Your turn at about', style: label)),
              LineStatusTag(moving: estimate.lineMoving),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            estimate.estimatedServiceStartLabel.isEmpty
                ? '—'
                : estimate.estimatedServiceStartLabel,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: AppColors.greenDark,
              height: 1.1,
              fontFeatures: _digits,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(child: Text('Waiting so far', style: label)),
              LiveCountUp(seconds: waitedSeconds, anchor: anchor, style: value),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(child: Text('Average service time', style: label)),
              Text(
                avg > 0 ? formatClock(avg) : '—',
                style: value.copyWith(fontFeatures: _digits),
              ),
            ],
          ),
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
        ],
      ),
    );
  }
}
