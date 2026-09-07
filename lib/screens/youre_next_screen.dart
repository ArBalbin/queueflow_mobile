import 'dart:async';

import 'package:flutter/material.dart';
import '../models/queue_models.dart';
import '../services/queue_api.dart';
import '../services/queue_navigation.dart';
import '../services/queue_session_store.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class YoureNextScreen extends StatefulWidget {
  const YoureNextScreen({super.key});

  @override
  State<YoureNextScreen> createState() => _YoureNextScreenState();
}

class _YoureNextScreenState extends State<YoureNextScreen> {
  Timer? _pollTimer;
  QueueSnapshot? _snapshot = QueueSessionStore.latestSnapshot;
  bool _isRefreshing = false;
  bool _isSendingOnWay = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _refresh(showSpinner: _snapshot == null);
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
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
      if (route != '/queue/next') {
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
        _errorMessage = 'Unable to refresh queue status.';
        _isRefreshing = false;
      });
    }
  }

  Future<void> _notifyOnTheWay() async {
    if (_isSendingOnWay || !QueueSessionStore.hasSession) return;
    setState(() {
      _isSendingOnWay = true;
      _errorMessage = null;
    });

    try {
      final snapshot = await QueueSessionStore.notifyOnTheWay();
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _isSendingOnWay = false;
      });
    } on QueueApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isSendingOnWay = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to notify staff. Please try again.';
        _isSendingOnWay = false;
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
        bgColor: const Color(0xFF0B5C47),
        logoColor: const Color(0xFF1D9E75),
        showBack: true,
        onBack: () => goBack(context),
      ),
      body: snapshot == null
          ? _EmptyNextState(isLoading: _isRefreshing)
          : _NextBody(
              snapshot: snapshot,
              isRefreshing: _isRefreshing,
              isSendingOnWay: _isSendingOnWay,
              errorMessage: _errorMessage,
              onRefresh: () => _refresh(showSpinner: true),
              onNotifyOnWay: _notifyOnTheWay,
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

class _NextBody extends StatelessWidget {
  final QueueSnapshot snapshot;
  final bool isRefreshing;
  final bool isSendingOnWay;
  final String? errorMessage;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onNotifyOnWay;

  const _NextBody({
    required this.snapshot,
    required this.isRefreshing,
    required this.isSendingOnWay,
    required this.errorMessage,
    required this.onRefresh,
    required this.onNotifyOnWay,
  });

  @override
  Widget build(BuildContext context) {
    final status = snapshot.status;
    final hasNotifiedStaff = status.onTheWay;
    QueuePerson? previousPerson;
    for (final person in snapshot.prediction.activeQueue) {
      if (person.position < status.positionInLine) {
        previousPerson = person;
      }
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            QueueNumberCard(
              number: status.queueDigits,
              label: 'Your Number',
              bg: AppColors.green,
              numColor: const Color(0xFF9FE1CB),
              badge: const QBadge(
                label: "You're Next!",
                bg: AppColors.greenLight,
                fg: AppColors.green,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                StatTile(
                  value: '${status.aheadCount}',
                  label: 'Ahead of you',
                  valueColor: AppColors.green,
                ),
                const SizedBox(width: 6),
                StatTile(
                  value: _waitValue(status.estimatedWaitMinutes),
                  label: 'Est. wait (min)',
                  valueColor: AppColors.green,
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
              text: "Make your way to the service area - you're almost up!",
              bg: AppColors.amberLight,
              borderColor: Color(0xFFEF9F27),
              dotColor: AppColors.amberBright,
              textColor: AppColors.amberText,
            ),
            const SizedBox(height: 8),
            AlertBanner(
              text: hasNotifiedStaff
                  ? 'Staff has been notified that you are on your way to the queue zone.'
                  : 'Tap the button below once you are heading to the queue zone.',
              bg: hasNotifiedStaff
                  ? AppColors.greenLight
                  : AppColors.purpleLight,
              borderColor: hasNotifiedStaff
                  ? AppColors.green
                  : AppColors.purple,
              dotColor: hasNotifiedStaff ? AppColors.green : AppColors.purple,
              textColor: hasNotifiedStaff
                  ? AppColors.green
                  : AppColors.purpleDark,
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
            const SectionLabel('Queue position'),
            const SizedBox(height: 6),
            if (previousPerson != null) ...[
              QueueListItem(
                number: previousPerson.queueDigits,
                title: 'Now serving',
                subtitle: previousPerson.estimatedWaitLabel,
                circBg: AppColors.purpleLight,
                circFg: AppColors.purpleDark,
                badge: const QBadge(
                  label: 'Serving',
                  bg: AppColors.amberLight,
                  fg: AppColors.amberText,
                ),
              ),
              const SizedBox(height: 6),
            ],
            QueueListItem(
              number: status.queueDigits,
              title: status.positionInLine <= 1
                  ? 'You - Next up!'
                  : 'You - Position ${status.positionInLine}',
              subtitle: status.positionInLine <= 1
                  ? 'Get ready'
                  : status.estimatedWaitLabel,
              circBg: AppColors.green,
              circFg: AppColors.white,
              titleColor: AppColors.green,
              highlighted: true,
              highlightColor: AppColors.green,
              badge: const QBadge(
                label: 'Next',
                bg: AppColors.greenLight,
                fg: AppColors.green,
              ),
            ),
            const SizedBox(height: 14),
            PrimaryButton(
              label: hasNotifiedStaff
                  ? 'Staff Notified'
                  : isSendingOnWay
                  ? 'Notifying Staff...'
                  : "I'm on my way to queue zone",
              bg: AppColors.green,
              onTap: hasNotifiedStaff || isSendingOnWay
                  ? null
                  : () => onNotifyOnWay(),
            ),
            const SizedBox(height: 8),
            PrimaryButton(
              label: isRefreshing ? 'Refreshing...' : 'Refresh Status',
              bg: AppColors.green,
              onTap: isRefreshing ? null : () => onRefresh(),
            ),
          ],
        ),
      ),
    );
  }

  String _waitValue(double minutes) {
    if (minutes <= 0) return '<1';
    return '~${minutes.ceil()}';
  }
}

class _EmptyNextState extends StatelessWidget {
  final bool isLoading;

  const _EmptyNextState({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            const CircularProgressIndicator(color: AppColors.green)
          else
            const Icon(
              Icons.confirmation_number_outlined,
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
