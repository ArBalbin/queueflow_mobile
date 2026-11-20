import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/payment_models.dart';
import '../models/queue_models.dart';
import '../services/queue_api.dart';
import '../services/queue_navigation.dart';
import '../services/queue_session_store.dart';
import '../theme/app_theme.dart';
import '../widgets/live_wait.dart';
import '../widgets/shared_widgets.dart';

/// Shown once the student's number is called to a window: which window to go
/// to, and that they are being served there. Moves on by itself when staff
/// mark the ticket done or a no-show.
class ServingScreen extends StatefulWidget {
  const ServingScreen({super.key});

  @override
  State<ServingScreen> createState() => _ServingScreenState();
}

class _ServingScreenState extends State<ServingScreen> {
  /// Numbers whose student said they are at the window, so the countdown
  /// stays hidden if this screen is opened again.
  static final Set<int> _arrived = {};

  Timer? _pollTimer;
  QueueSnapshot? _snapshot = QueueSessionStore.latestSnapshot;
  bool _isRefreshing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // The phone may be in a pocket: a strong buzz says "your turn".
    HapticFeedback.heavyImpact();
    _refresh();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _refresh());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_isRefreshing || !QueueSessionStore.hasSession) return;
    _isRefreshing = true;
    try {
      final snapshot = await QueueSessionStore.refresh();
      if (!mounted) return;
      final route = routeForQueueSnapshot(snapshot);
      if (route != '/queue/serving') {
        Navigator.pushReplacementNamed(context, route);
        return;
      }
      setState(() {
        _snapshot = snapshot;
        _errorMessage = null;
      });
    } on QueueApiException catch (error) {
      if (!mounted) return;
      if (error.statusCode == 404 && _snapshot != null) {
        Navigator.pushReplacementNamed(context, '/queue/complete');
        return;
      }
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Unable to refresh queue status.');
    } finally {
      _isRefreshing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _snapshot?.status;
    final window = status?.counterNumber;
    final queueLabel =
        status?.queueLabel ?? QueueSessionStore.credentials?.queueLabel ?? '';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: QAppBar(
        title: 'My Queue Status',
        bgColor: AppColors.greenDark,
        showBack: true,
        onBack: () => goBack(context),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.green,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    const Text(
                      "IT'S YOUR TURN",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xCCFFFFFF),
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      window == null ? 'Window' : 'Window $window',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Your number: $queueLabel',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (status != null &&
                  status.secondsAtCounter != null &&
                  !_arrived.contains(status.queueNumber)) ...[
                _ArriveTimer(
                  window: window,
                  secondsSinceCalled: status.secondsAtCounter!,
                  limitSeconds: status.arriveWithinSeconds,
                  anchor: _snapshot!.fetchedAt,
                  onArrived: () =>
                      setState(() => _arrived.add(status.queueNumber)),
                ),
                const SizedBox(height: 12),
              ],
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.storefront_rounded,
                      color: AppColors.green,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        window == null
                            ? 'Go to the cashier window now. You are being served there.'
                            : 'Go to Window $window now. You are being served there; '
                                  'this screen changes when the cashier finishes.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.dark,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (status?.paymentType != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.payments_rounded,
                        color: AppColors.green,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Have your payment ready',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              status!.paymentAmount != null
                                  ? '${status.paymentType} · ${formatPeso(status.paymentAmount!)}'
                                  : status.paymentType!,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.dark,
                              ),
                            ),
                            if (status.paymentNote != null)
                              Text(
                                status.paymentNote!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.dark,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                AlertBanner(
                  text: _errorMessage!,
                  bg: AppColors.redLight,
                  borderColor: AppColors.red,
                  dotColor: AppColors.redDark,
                  textColor: AppColors.redDark,
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: QBottomNavBar(
        currentIndex: 0,
        onTap: (i) {
          if (i != 0) {
            switchTab(context, i);
          }
        },
      ),
    );
  }
}

/// The time the student has to reach their window, counted down from the
/// moment it was called. When it runs out the student is told to hurry; the
/// number is not skipped by the app. Staff decide that at the window.
class _ArriveTimer extends StatelessWidget {
  final int? window;
  final int secondsSinceCalled;
  final int limitSeconds;
  final DateTime anchor;
  final VoidCallback onArrived;

  const _ArriveTimer({
    required this.window,
    required this.secondsSinceCalled,
    required this.limitSeconds,
    required this.anchor,
    required this.onArrived,
  });

  @override
  Widget build(BuildContext context) {
    final place = window == null ? 'the window' : 'Window $window';
    return Ticking(
      anchor: anchor,
      builder: (context, since) {
        final left = limitSeconds - (secondsSinceCalled + since);
        final over = left <= 0;
        final hurry = !over && left <= 15;
        final fg = over
            ? AppColors.redDark
            : hurry
            ? AppColors.amberText
            : AppColors.greenDark;
        final bg = over
            ? AppColors.redLight
            : hurry
            ? AppColors.amberLight
            : AppColors.greenLight;
        final total = limitSeconds <= 0 ? 1 : limitSeconds;
        final progress = over ? 0.0 : (left / total).clamp(0.0, 1.0);
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    over ? Icons.directions_run_rounded : Icons.timer_rounded,
                    size: 18,
                    color: fg,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      over ? 'Time is up' : 'Reach $place within',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                    ),
                  ),
                  Text(
                    over ? '+${formatClock(-left)}' : formatClock(left),
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: fg,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppColors.white,
                  valueColor: AlwaysStoppedAnimation<Color>(fg),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                over
                    ? 'Go to $place now. Staff may skip a number that does not '
                          'come to its window.'
                    : 'Your number was called. Go to $place with your payment '
                          'before the time runs out.',
                style: TextStyle(fontSize: 13, color: fg, height: 1.4),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onArrived,
                  icon: Icon(Icons.check_circle_rounded, size: 18, color: fg),
                  label: Text(
                    "I'm at the window",
                    style: TextStyle(fontWeight: FontWeight.w700, color: fg),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
