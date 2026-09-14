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
        bgColor: AppColors.greenDark,
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

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            color: AppColors.green,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Same fix as youre_next_screen: the stat card is laid out in
                  // the same Column as the status pill instead of hanging off
                  // the header with Positioned(bottom: -26), so the gap between
                  // them is a real SizedBox rather than a match between the
                  // header's bottom padding and the card's height. Only 6dp
                  // separated them before, which a larger system font erases.
                  Stack(
                    clipBehavior: Clip.none,
                    fit: StackFit.passthrough,
                    children: [
                      const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        bottom: 26,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.green,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(28),
                              bottomRight: Radius.circular(28),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Column(
                          children: [
                            const Text(
                              'YOUR QUEUE NUMBER',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xB3FFFFFF),
                                letterSpacing: 1.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              status.queueDigits,
                              style: const TextStyle(
                                fontSize: 56,
                                fontWeight: FontWeight.w800,
                                color: AppColors.white,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    status.isMissing
                                        ? Icons.warning_amber_rounded
                                        : Icons.access_time_filled_rounded,
                                    size: 14,
                                    color: status.isMissing
                                        ? AppColors.amberText
                                        : AppColors.green,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    status.isMissing
                                        ? 'Status: Missing'
                                        : 'Waiting in line',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: status.isMissing
                                          ? AppColors.amberText
                                          : AppColors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1A000000),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _StatColumn(
                                  value: '${status.aheadCount}',
                                  label: 'Ahead of you',
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 28,
                                color: AppColors.border,
                              ),
                              Expanded(
                                child: _StatColumn(
                                  value: _waitValue(
                                    status.estimatedWaitMinutes,
                                  ),
                                  label: 'Est. wait (min)',
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 28,
                                color: AppColors.border,
                              ),
                              Expanded(
                                child: _StatColumn(
                                  value: snapshot.activeCounters > 0
                                      ? '${snapshot.activeCounters}'
                                      : '-',
                                  label: 'Counters open',
                                ),
                              ),
                            ],
                          ),
                        ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (errorMessage != null) ...[
                          AlertBanner(
                            text: errorMessage!,
                            bg: AppColors.redLight,
                            borderColor: AppColors.red,
                            dotColor: AppColors.redDark,
                            textColor: AppColors.redDark,
                          ),
                          const SizedBox(height: 16),
                        ],
                        const Row(
                          children: [
                            Icon(
                              Icons.groups_rounded,
                              size: 16,
                              color: AppColors.green,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Queue ahead of you',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.dark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ..._queueItems(snapshot),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          decoration: const BoxDecoration(
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 16,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: PrimaryButton(
            label: isRefreshing ? 'Refreshing Status...' : 'Refresh Status',
            bg: AppColors.green,
            padding: const EdgeInsets.symmetric(vertical: 16),
            fontSize: 14,
            onTap: isRefreshing ? null : () => onRefresh(),
          ),
        ),
      ],
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
        padding: const EdgeInsets.only(bottom: 10),
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
              ? AppColors.amberLight
              : AppColors.border,
          circFg: isCurrentUser
              ? AppColors.white
              : isNowServing
              ? AppColors.amberText
              : AppColors.textMuted,
          titleColor: isCurrentUser ? AppColors.greenDark : null,
          highlighted: isCurrentUser,
          highlightColor: AppColors.green,
          badge: isCurrentUser
              ? const QBadge(
                  label: 'You',
                  bg: AppColors.greenLight,
                  fg: AppColors.greenDark,
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

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;
  const _StatColumn({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _EmptyQueueState extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;

  const _EmptyQueueState({required this.isLoading, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(
              color: AppColors.greenLight,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: isLoading
                ? const CircularProgressIndicator(color: AppColors.green)
                : const Icon(
                    Icons.confirmation_number_outlined,
                    size: 36,
                    color: AppColors.green,
                  ),
          ),
          const SizedBox(height: 18),
          Text(
            errorMessage ?? 'No active ticket loaded',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter your queue number and access token to check your live status.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Enter Ticket Details',
            bg: AppColors.green,
            padding: const EdgeInsets.symmetric(vertical: 15),
            fontSize: 14,
            onTap: () =>
                Navigator.pushReplacementNamed(context, '/ticket/lookup'),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        'Queue line data is not available yet.',
        style: AppText.bodyMuted,
      ),
    );
  }
}
