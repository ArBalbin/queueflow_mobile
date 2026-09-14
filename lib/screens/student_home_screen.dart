import 'dart:async';

import 'package:flutter/material.dart';

import '../models/queue_models.dart';
import '../services/queue_navigation.dart';
import '../services/queue_session_store.dart';
import '../services/student_session_store.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  bool _pendingLink = false;
  bool _joined = false;
  bool _joinBusy = false;
  QueuePrediction? _prediction;
  bool _isNavigating = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _refresh();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    await Future.wait([_checkMyQueue(), _fetchPrediction()]);
  }

  Future<void> _checkMyQueue() async {
    final token = StudentSessionStore.sessionToken;
    if (token == null || _isNavigating) return;

    try {
      final entry = await StudentSessionStore.api.getMyQueueEntry(token);

      if (entry.hasActiveEntry && entry.queueNumber != null && entry.accessToken != null) {
        _isNavigating = true;
        final snapshot = await QueueSessionStore.startSessionWithCredentials(
          QueueCredentials(queueNumber: entry.queueNumber!, accessToken: entry.accessToken!),
        );
        if (!mounted) return;

        if (snapshot.status.isDone) {
          QueueSessionStore.clear();
          _isNavigating = false;
          return;
        }

        _pollTimer?.cancel();
        Navigator.of(context).pushReplacementNamed(routeForQueueSnapshot(snapshot));
        return;
      }

      if (mounted) {
        setState(() {
          _pendingLink = entry.pendingLink;
          if (!_joinBusy) _joined = entry.joined;
        });
      }
    } catch (_) {}
  }

  Future<void> _setJoined(bool value) async {
    final token = StudentSessionStore.sessionToken;
    if (token == null || _joinBusy) return;

    setState(() => _joinBusy = true);
    try {
      if (value) {
        await StudentSessionStore.api.joinQueue(token);
      } else {
        await StudentSessionStore.api.cancelJoinQueue(token);
      }
      if (!mounted) return;
      setState(() {
        _joined = value;
        _joinBusy = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _joinBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? "Couldn't join the queue. Check your connection and try again."
                : "Couldn't cancel. Try again.",
          ),
        ),
      );
    }
  }

  Future<void> _fetchPrediction() async {
    try {
      final prediction = await QueueSessionStore.api.fetchQueuePrediction();
      if (mounted) setState(() => _prediction = prediction);
    } catch (_) {}
  }

  Future<void> _logout(BuildContext context) async {
    await StudentSessionStore.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/student/login',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = StudentSessionStore.profile;
    final faceRegistered = profile?.hasFaceEmbedding == true;
    final prediction = _prediction;
    final name = profile?.fullName?.isNotEmpty == true ? profile!.fullName! : 'Student';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.green,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Image.asset('assets/img/Logo.png', height: 26, fit: BoxFit.contain),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.green,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              _IdentityCard(
                name: name,
                schoolId: profile?.schoolId ?? '-',
                faceRegistered: faceRegistered,
              ),
              const SizedBox(height: 20),

              const SectionLabel('QUEUE RIGHT NOW'),
              const SizedBox(height: 8),
              _StatsCard(
                inLine: prediction == null ? '—' : '${prediction.queueLength}',
                wait: prediction == null ? '—' : prediction.newArrivalWaitLabel,
                counters: prediction == null ? '—' : '${prediction.activeCounters}',
              ),
              const SizedBox(height: 20),

              const SectionLabel('YOUR STATUS'),
              const SizedBox(height: 8),
              if (!faceRegistered)
                _StatusCard(
                  icon: Icons.face_retouching_natural_rounded,
                  iconBg: AppColors.amberLight,
                  iconColor: AppColors.amberBright,
                  title: 'Register your face',
                  message:
                      "You haven't registered your face yet. Do this before "
                      'visiting the queue area so the camera can recognize you.',
                  action: PrimaryButton(
                    label: 'Register My Face',
                    bg: AppColors.green,
                    onTap: () => Navigator.of(context).pushNamed('/student/face-capture'),
                  ),
                )
              else if (_pendingLink)
                _StatusCard(
                  icon: Icons.sync_rounded,
                  iconBg: AppColors.greenLight,
                  iconColor: AppColors.green,
                  title: 'Confirming your identity',
                  message: 'The camera sees you in the queue area — confirming your identity now.',
                  action: Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.green),
                      ),
                      const SizedBox(width: 8),
                      Text('Please wait', style: AppText.caption),
                    ],
                  ),
                )
              else if (_joined)
                _StatusCard(
                  icon: Icons.check_circle_rounded,
                  iconBg: AppColors.greenLight,
                  iconColor: AppColors.green,
                  title: "You're in the queue",
                  message:
                      'Walk up to the queue-area camera — it will recognize you and issue '
                      'your number automatically. This screen opens your live status the '
                      'moment it does.',
                  action: PrimaryButton(
                    label: _joinBusy ? 'Cancelling…' : "Cancel — I'm not queueing",
                    outlined: true,
                    borderColor: AppColors.borderMid,
                    fg: AppColors.dark,
                    onTap: _joinBusy ? null : () => _setJoined(false),
                  ),
                )
              else
                _StatusCard(
                  icon: Icons.qr_code_scanner_rounded,
                  iconBg: AppColors.greenLight,
                  iconColor: AppColors.green,
                  title: 'Ready to join the queue?',
                  message:
                      'The camera will not give you a number until you join. Tap below '
                      'when you actually want to queue, then walk up to the camera.',
                  action: PrimaryButton(
                    label: _joinBusy ? 'Joining…' : 'Join the Queue',
                    bg: AppColors.green,
                    onTap: _joinBusy ? null : () => _setJoined(true),
                  ),
                ),
              const SizedBox(height: 20),

              const SectionLabel('WHAT YOU CAN DO'),
              const SizedBox(height: 8),
              _ActionCard(
                children: [
                  const _ActionRow(
                    icon: Icons.visibility_outlined,
                    title: 'Join, then go to the queue area',
                    subtitle:
                        'Tap "Join the Queue" first, then stand where the camera can see '
                        'your face. It only issues a number to students who have joined.',
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  _ActionRow(
                    icon: Icons.confirmation_number_outlined,
                    title: 'Track a printed ticket',
                    subtitle: 'Holding a kiosk ticket instead? Check its status here.',
                    onTap: () => Navigator.of(context).pushNamed('/ticket/lookup'),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              Center(
                child: GestureDetector(
                  onTap: () => _logout(context),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Log Out',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.red),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  final String name;
  final String schoolId;
  final bool faceRegistered;
  const _IdentityCard({
    required this.name,
    required this.schoolId,
    required this.faceRegistered,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.greenLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded, color: AppColors.greenDark, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppText.heading),
                const SizedBox(height: 2),
                Text('ID: $schoolId', style: AppText.caption),
              ],
            ),
          ),
          QBadge(
            label: faceRegistered ? 'Face registered' : 'Face not set up',
            bg: faceRegistered ? AppColors.greenLight : AppColors.amberLight,
            fg: faceRegistered ? AppColors.green : AppColors.amber,
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final String inLine;
  final String wait;
  final String counters;
  const _StatsCard({required this.inLine, required this.wait, required this.counters});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        children: [
          Expanded(child: _StatColumn(value: inLine, label: 'In line')),
          const _StatDivider(),
          Expanded(child: _StatColumn(value: wait, label: 'Wait now')),
          const _StatDivider(),
          Expanded(child: _StatColumn(value: counters, label: 'Counters')),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;
  const _StatColumn({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.dark)),
        const SizedBox(height: 4),
        Text(label, textAlign: TextAlign.center, style: AppText.caption),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 100, color: AppColors.border);
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String message;
  final Widget? action;
  const _StatusCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.heading),
                    const SizedBox(height: 4),
                    Text(message, style: AppText.bodyMuted),
                  ],
                ),
              ),
            ],
          ),
          if (action != null) ...[
            const SizedBox(height: 14),
            action!,
          ],
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final List<Widget> children;
  const _ActionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.greenLight, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: AppColors.greenDark, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.label),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppText.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textLight, size: 18),
          ],
        ),
      ),
    );
  }
}