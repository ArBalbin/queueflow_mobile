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
        bgColor: AppColors.greenDark,
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
                  // The stat chips straddle the bottom edge of the green header.
                  // They used to hang off it via Positioned(bottom: -28), outside
                  // the layout, so the space between the status pill and the
                  // chips depended on two hand-matched numbers: the header's
                  // bottom padding (44) versus how far the chips reach up into
                  // it (chip height minus the overhang, ~49). The chips won, and
                  // covered the pill; a larger system font made it worse.
                  //
                  // Now the chips sit in the same Column as the pill, so the gap
                  // between them is a real SizedBox that cannot collapse, and the
                  // green is a background layer that simply stops 28dp above the
                  // chips' bottom edge.
                  Stack(
                    clipBehavior: Clip.none,
                    fit: StackFit.passthrough,
                    children: [
                      const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        bottom: 28,
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
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
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
                              status.queueLabel,
                              style: const TextStyle(
                                fontSize: 60,
                                fontWeight: FontWeight.w800,
                                color: AppColors.white,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.bolt_rounded,
                                    size: 14,
                                    color: AppColors.green,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    status.positionInLine <= 1
                                        ? "You're up next!"
                                        : 'Position ${status.positionInLine} in line',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                          children: [
                            Expanded(
                              child: _StatChip(
                                icon: Icons.people_alt_rounded,
                                value: '${status.aheadCount}',
                                label: 'Ahead of you',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _StatChip(
                                icon: Icons.schedule_rounded,
                                value: '${_waitValue(status.estimatedWaitMinutes)} min',
                                label: 'Est. wait',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _StatChip(
                                icon: Icons.storefront_rounded,
                                value: snapshot.activeCounters > 0
                                    ? '${snapshot.activeCounters}'
                                    : '-',
                                label: 'Counters open',
                              ),
                            ),
                          ],
                        ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
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
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your journey',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.dark,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _TimelineStep(
                                icon: Icons.check_rounded,
                                label: 'Joined the queue',
                                time: status.joinedAt,
                                done: true,
                              ),
                              _TimelineStep(
                                icon: hasNotifiedStaff
                                    ? Icons.check_rounded
                                    : Icons.directions_walk_rounded,
                                label: hasNotifiedStaff
                                    ? 'Notified staff you are on your way'
                                    : 'Notify staff when you head over',
                                time: hasNotifiedStaff ? status.onTheWayAt : null,
                                done: hasNotifiedStaff,
                                active: !hasNotifiedStaff,
                                isLast: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(
                                    Icons.groups_rounded,
                                    size: 16,
                                    color: AppColors.green,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Queue position',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.dark,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _PersonAvatar(
                                    label: 'Now serving',
                                    number: previousPerson?.queueDigits ?? '—',
                                    color: AppColors.amberBright,
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        color: AppColors.textLight,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${status.aheadCount} ahead',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  _PersonAvatar(
                                    label: status.positionInLine <= 1
                                        ? "You're next"
                                        : 'You',
                                    number: status.queueDigits,
                                    color: AppColors.green,
                                    emphasized: true,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _BottomActionBar(
          hasNotifiedStaff: hasNotifiedStaff,
          isSendingOnWay: isSendingOnWay,
          isRefreshing: isRefreshing,
          onNotify: hasNotifiedStaff || isSendingOnWay
              ? null
              : () => onNotifyOnWay(),
          onRefresh: isRefreshing ? null : () => onRefresh(),
        ),
      ],
    );
  }

  String _waitValue(double minutes) {
    if (minutes <= 0) return '<1';
    return '~${minutes.ceil()}';
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.green),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? time;
  final bool done;
  final bool active;
  final bool isLast;
  const _TimelineStep({
    required this.icon,
    required this.label,
    this.time,
    required this.done,
    this.active = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = done
        ? AppColors.green
        : (active ? AppColors.amberBright : AppColors.textMuted);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: done ? AppColors.green : AppColors.bg,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 14,
                  color: done ? AppColors.white : color,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: done ? AppColors.green : AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dark,
                    ),
                  ),
                  if (time != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      time!,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonAvatar extends StatelessWidget {
  final String label;
  final String number;
  final Color color;
  final bool emphasized;
  const _PersonAvatar({
    required this.label,
    required this.number,
    required this.color,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = emphasized ? 64.0 : 52.0;
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: emphasized ? color : color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: emphasized ? null : Border.all(color: color, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: TextStyle(
              fontSize: emphasized ? 16 : 13,
              fontWeight: FontWeight.w700,
              color: emphasized ? AppColors.white : color,
            ),
          ),
        ),
        const SizedBox(height: 6),
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

class _BottomActionBar extends StatelessWidget {
  final bool hasNotifiedStaff;
  final bool isSendingOnWay;
  final bool isRefreshing;
  final VoidCallback? onNotify;
  final VoidCallback? onRefresh;
  const _BottomActionBar({
    required this.hasNotifiedStaff,
    required this.isSendingOnWay,
    required this.isRefreshing,
    required this.onNotify,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: const BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: PrimaryButton(
              label: hasNotifiedStaff
                  ? 'Staff Notified'
                  : isSendingOnWay
                  ? 'Notifying Staff...'
                  : "I'm on my way",
              bg: AppColors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
              fontSize: 14,
              onTap: onNotify,
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onRefresh,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.greenLight,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: isRefreshing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.green,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded, color: AppColors.green),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyNextState extends StatelessWidget {
  final bool isLoading;

  const _EmptyNextState({required this.isLoading});

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
          const Text(
            'No active ticket loaded',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter your queue number and access token to check your live status.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Enter Ticket Details',
            bg: AppColors.green,
            padding: const EdgeInsets.symmetric(vertical: 15),
            fontSize: 14,
            onTap: () => Navigator.pushReplacementNamed(context, '/ticket/lookup'),
          ),
        ],
      ),
    );
  }
}