import 'dart:async';

import 'package:flutter/material.dart';
import '../models/queue_models.dart';
import '../services/queue_api.dart';
import '../services/queue_navigation.dart';
import '../services/queue_session_store.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class QueueWaitingScreen extends StatefulWidget {
  const QueueWaitingScreen({super.key});

  @override
  State<QueueWaitingScreen> createState() => _QueueWaitingScreenState();
}

class _QueueWaitingScreenState extends State<QueueWaitingScreen> {
  Timer? _pollTimer;
  QueueSnapshot? _snapshot = QueueSessionStore.latestSnapshot;
  bool _isRefreshing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _refresh(showSpinner: _snapshot == null);
    _pollTimer = Timer.periodic(const Duration(seconds: 6), (_) => _refresh());
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
      if (route != '/queue/waiting') {
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

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: QAppBar(
        title: 'My Queue Status',
        showBack: true,
        onBack: () => goBack(context),
      ),
      body: snapshot == null
          ? _EmptyQueueState(
              isLoading: _isRefreshing,
              errorMessage: _errorMessage,
            )
          : _WaitingBody(
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

class _WaitingBody extends StatelessWidget {
  final QueueSnapshot snapshot;
  final bool isRefreshing;
  final String? errorMessage;
  final Future<void> Function() onRefresh;

  const _WaitingBody({
    required this.snapshot,
    required this.isRefreshing,
    required this.errorMessage,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final status = snapshot.status;

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
              bg: AppColors.dark,
              numColor: const Color(0xFFA29EF0),
              badge: QBadge(
                label: status.isMissing ? 'Missing' : 'Waiting',
                bg: status.isMissing
                    ? AppColors.amberLight
                    : AppColors.purpleLight,
                fg: status.isMissing
                    ? AppColors.amberText
                    : AppColors.purpleDark,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                StatTile(value: '${status.aheadCount}', label: 'Ahead of you'),
                const SizedBox(width: 6),
                StatTile(
                  value: _waitValue(status.estimatedWaitMinutes),
                  label: 'Est. wait (min)',
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
            const SectionLabel('Queue ahead of you'),
            const SizedBox(height: 6),
            ..._queueItems(snapshot),
            const SizedBox(height: 14),
            PrimaryButton(
              label: isRefreshing ? 'Refreshing...' : 'Refresh Status',
              onTap: isRefreshing ? null : () => onRefresh(),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _queueItems(QueueSnapshot snapshot) {
    final status = snapshot.status;
    final people = snapshot.visibleLine;

    if (people.isEmpty) {
      return [const _EmptyLineCard()];
    }

    return people.map((person) {
      final isCurrentUser = person.queueNumber == status.queueNumber;
      final isNowServing = person.position <= 1 && !isCurrentUser;

      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: QueueListItem(
          number: person.queueDigits,
          title: isCurrentUser
              ? 'You - Position ${status.positionInLine}'
              : isNowServing
              ? 'Now serving'
              : 'Position ${person.position}',
          subtitle: isCurrentUser
              ? status.estimatedWaitLabel
              : person.estimatedWaitLabel,
          circBg: isCurrentUser
              ? AppColors.dark
              : isNowServing
              ? AppColors.purpleLight
              : const Color(0xFFF1EFE8),
          circFg: isCurrentUser
              ? AppColors.white
              : isNowServing
              ? AppColors.purpleDark
              : const Color(0xFF444444),
          titleColor: isCurrentUser ? AppColors.purpleDark : null,
          highlighted: isCurrentUser,
          highlightColor: AppColors.purple,
          badge: isCurrentUser
              ? const QBadge(
                  label: 'You',
                  bg: AppColors.purpleLight,
                  fg: AppColors.purpleDark,
                )
              : isNowServing
              ? const QBadge(
                  label: 'Serving',
                  bg: AppColors.amberLight,
                  fg: AppColors.amberText,
                )
              : null,
        ),
      );
    }).toList();
  }

  String _waitValue(double minutes) {
    if (minutes <= 0) return '<1';
    return '~${minutes.ceil()}';
  }
}

class _EmptyQueueState extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;

  const _EmptyQueueState({required this.isLoading, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            const CircularProgressIndicator(color: AppColors.dark)
          else
            const Icon(
              Icons.confirmation_number_outlined,
              size: 42,
              color: AppColors.textMuted,
            ),
          const SizedBox(height: 12),
          Text(
            errorMessage ?? 'No active ticket loaded.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
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

class _EmptyLineCard extends StatelessWidget {
  const _EmptyLineCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'Queue line data is not available yet.',
        style: TextStyle(fontSize: 10, color: AppColors.textMuted),
      ),
    );
  }
}
