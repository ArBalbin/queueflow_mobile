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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: QAppBar(
        title: 'My Queue Status',
        bgColor: const Color(0xFF7A3300),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.8),
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _StatColumn(
                    icon: Icons.people_alt_rounded,
                    value: '${status.aheadCount}',
                    label: 'Ahead',
                    color: AppColors.amberBright,
                  ),
                ),
                Container(width: 1, height: 36, color: AppColors.border),
                Expanded(
                  child: _StatColumn(
                    icon: Icons.timer_outlined,
                    value: _durationLabel(remaining),
                    label: 'Remaining',
                    color: AppColors.amberBright,
                  ),
                ),
                Container(width: 1, height: 36, color: AppColors.border),
                Expanded(
                  child: _StatColumn(
                    icon: Icons.store_rounded,
                    value: snapshot.activeCounters > 0
                        ? '${snapshot.activeCounters}'
                        : '-',
                    label: 'Counters',
                    color: AppColors.dark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const AlertBanner(
            text:
                'You are not detected in the queue area. Return before the countdown ends or your ticket may be skipped.',
            bg: AppColors.redLight,
            borderColor: AppColors.red,
            dotColor: AppColors.redDark,
            textColor: AppColors.redDark,
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            AlertBanner(
              text: errorMessage!,
              bg: AppColors.redLight,
              borderColor: AppColors.red,
              dotColor: AppColors.redDark,
              textColor: AppColors.redDark,
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.8),
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.hourglass_bottom_rounded,
                          size: 16,
                          color: AppColors.red,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'No-show countdown',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.dark,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.redLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$remaining s',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.red,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (remaining / 180).clamp(0, 1).toDouble(),
                    backgroundColor: AppColors.border,
                    color: AppColors.red,
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 10),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Auto-skipping soon if undetected',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Text(
                      'QueuEx protection',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: AppColors.amberDark.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              borderRadius: BorderRadius.circular(16),
            ),
            child: PrimaryButton(
              label: isRefreshing
                  ? 'Checking Status...'
                  : "I'm here - Refresh Status",
              bg: AppColors.amberDark,
              padding: const EdgeInsets.symmetric(vertical: 16),
              fontSize: 14,
              onTap: isRefreshing ? null : () => onRefresh(),
            ),
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

class _StatColumn extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatColumn({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color.withValues(alpha: 0.8)),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _EmptyWarningState extends StatelessWidget {
  const _EmptyWarningState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.amberLight,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                size: 40,
                color: AppColors.amberDark,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No active ticket loaded',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Load a ticket to view active status details.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Enter Ticket Details',
              bg: AppColors.green,
              padding: const EdgeInsets.symmetric(vertical: 14),
              fontSize: 14,
              onTap: () =>
                  Navigator.pushReplacementNamed(context, '/ticket/lookup'),
            ),
          ],
        ),
      ),
    );
  }
}
