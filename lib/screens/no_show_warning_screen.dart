import 'dart:async';

import 'package:flutter/material.dart';
import '../models/queue_models.dart';
import '../services/queue_api.dart';
import '../services/queue_navigation.dart';
import '../services/queue_session_store.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class NoShowWarningScreen extends StatefulWidget {
  const NoShowWarningScreen({super.key});

  @override
  State<NoShowWarningScreen> createState() => _NoShowWarningScreenState();
}

class _NoShowWarningScreenState extends State<NoShowWarningScreen> {
  Timer? _pollTimer;
  QueueSnapshot? _snapshot = QueueSessionStore.latestSnapshot;
  bool _isRefreshing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _refresh(showSpinner: _snapshot == null);
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _refresh());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh({bool showSpinner = false}) async {
    if (_isRefreshing || !QueueSessionStore.hasSession) return;
    if (showSpinner && mounted) {
      setState(() => _isRefreshing = true);
    } else {
      _isRefreshing = true;
    }

    try {
      final snapshot = await QueueSessionStore.refresh();
      if (!mounted) return;
      final route = routeForQueueSnapshot(snapshot);
      if (route != '/queue/noshow') {
        Navigator.pushReplacementNamed(context, route);
        return;
      }
      setState(() {
        _snapshot = snapshot;
        _errorMessage = null;
        _isRefreshing = false;
      });
    } on QueueApiException catch (error) {
      if (!mounted) return;
      if (error.statusCode == 404 && _snapshot != null) {
        Navigator.pushReplacementNamed(context, '/queue/complete');
        return;
      }
      setState(() {
        _errorMessage = error.message;
        _isRefreshing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to refresh no-show timer.';
        _isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: QAppBar(
        title: 'My Queue Status',
        bgColor: const Color(0xFF7A3300),
        logoColor: const Color(0xFFBA7517),
        showBack: true,
        onBack: () => goBack(context),
      ),
      body: snapshot == null
          ? const _EmptyWarningState()
          : _NoShowBody(
              snapshot: snapshot,
              isRefreshing: _isRefreshing,
              errorMessage: _errorMessage,
              onRefresh: () => _refresh(showSpinner: true),
            ),
      bottomNavigationBar: QBottomNavBar(
        currentIndex: 0,
        onTap: (i) {
          if (i != 0) {
            Navigator.pushReplacementNamed(context, routeForBottomNavIndex(i));
          }
        },
      ),
    );
  }
}

class _NoShowBody extends StatelessWidget {
  final QueueSnapshot snapshot;
  final bool isRefreshing;
  final String? errorMessage;
  final Future<void> Function() onRefresh;

  const _NoShowBody({
    required this.snapshot,
    required this.isRefreshing,
    required this.errorMessage,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final status = snapshot.status;
    final remaining = status.noshowCountdown ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          QueueNumberCard(
            number: status.queueDigits,
            label: 'Your Number',
            bg: AppColors.amber,
            numColor: AppColors.amberGold,
            badge: const QBadge(
              label: 'Action Required',
              bg: AppColors.amberLight,
              fg: AppColors.amberText,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              StatTile(
                value: '${status.aheadCount}',
                label: 'Ahead of you',
                valueColor: AppColors.amberBright,
              ),
              const SizedBox(width: 6),
              StatTile(
                value: _durationLabel(remaining),
                label: 'Time remaining',
                valueColor: AppColors.amberBright,
              ),
              const SizedBox(width: 6),
              StatTile(
                value: snapshot.activeCounters > 0
                    ? '${snapshot.activeCounters}'
                    : '-',
                label: 'Counters open',
              ),
            ],
          ),
          const SizedBox(height: 8),
          const AlertBanner(
            text:
                'You are not detected in the queue area. Return before the countdown ends or your number may be skipped.',
            bg: AppColors.redLight,
            borderColor: AppColors.red,
            dotColor: AppColors.redDark,
            textColor: AppColors.redDark,
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 8),
            AlertBanner(
              text: errorMessage!,
              bg: AppColors.redLight,
              borderColor: AppColors.red,
              dotColor: AppColors.redDark,
              textColor: AppColors.redDark,
            ),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'No-show countdown',
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: (remaining / 180).clamp(0, 1).toDouble(),
                    backgroundColor: const Color(0xFFF0F0F4),
                    color: AppColors.red,
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$remaining s remaining',
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Text(
                      'QueuEx timer',
                      style: TextStyle(fontSize: 9, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          PrimaryButton(
            label: isRefreshing ? 'Checking...' : "I'm here - Refresh Status",
            bg: AppColors.amberDark,
            onTap: isRefreshing ? null : () => onRefresh(),
          ),
        ],
      ),
    );
  }

  String _durationLabel(int seconds) {
    if (seconds <= 0) return '0:00';
    final minutes = seconds ~/ 60;
    final remainder = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainder';
  }
}

class _EmptyWarningState extends StatelessWidget {
  const _EmptyWarningState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 42,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 12),
          const Text(
            'No active ticket loaded.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Enter Ticket Details',
            onTap: () => Navigator.pushReplacementNamed(context, '/ticket/lookup'),
          ),
        ],
      ),
    );
  }
}
