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
    // Keep checking while this screen is open — the moment the camera
    // recognizes the student and the system issues their number, jump
    // straight into the live status screens without them doing anything.
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

        // Never drag the student into an already-finished session — that is
        // the screen they just dismissed to get here, and re-entering it
        // bounces them between the dashboard and "session ended" forever.
        // Stay put and keep polling for their *next* queue entry.
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
          // Don't let a poll overwrite the state mid-tap.
          if (!_joinBusy) _joined = entry.joined;
        });
      }
    } catch (_) {
      // Silent — this is a background convenience check, not a user action.
    }
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
    } catch (_) {
      // Silent — the dashboard falls back to "—" for the live numbers.
    }
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

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: const QAppBar(title: 'QueuEx'),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            // Extra bottom room so the last control clears the device's
            // gesture/navigation bar instead of sitting under it.
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              _IdentityCard(
                name: profile?.fullName?.isNotEmpty == true
                    ? profile!.fullName!
                    : 'Student',
                schoolId: profile?.schoolId ?? '-',
                faceRegistered: faceRegistered,
              ),
              const SizedBox(height: 20),

              const SectionLabel('QUEUE RIGHT NOW'),
              const SizedBox(height: 8),
              Row(
                children: [
                  StatTile(
                    value: prediction == null
                        ? '—'
                        : '${prediction.queueLength}',
                    label: 'In line',
                  ),
                  const SizedBox(width: 8),
                  StatTile(
                    value: prediction == null
                        ? '—'
                        : prediction.newArrivalWaitLabel,
                    label: 'Wait if you arrive now',
                  ),
                  const SizedBox(width: 8),
                  StatTile(
                    value: prediction == null
                        ? '—'
                        : '${prediction.activeCounters}',
                    label: 'Counters open',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              const SectionLabel('YOUR STATUS'),
              const SizedBox(height: 8),
              if (!faceRegistered) ...[
                AlertBanner(
                  text:
                      "You haven't registered your face yet. Do this before "
                      'visiting the queue area so the camera can recognize you.',
                  bg: AppColors.amberLight,
                  borderColor: AppColors.amberGold,
                  dotColor: AppColors.amberBright,
                  textColor: AppColors.amberText,
                ),
                const SizedBox(height: 10),
                PrimaryButton(
                  label: 'Register My Face',
                  onTap: () => Navigator.of(
                    context,
                  ).pushNamed('/student/face-capture'),
                ),
              ] else if (_pendingLink) ...[
                AlertBanner(
                  text: 'The camera sees you in the queue area — confirming '
                      'your identity now…',
                  bg: AppColors.purpleLight,
                  borderColor: AppColors.purple,
                  dotColor: AppColors.purpleDark,
                  textColor: AppColors.purpleDark,
                ),
              ] else if (_joined) ...[
                AlertBanner(
                  text: "You're in. Walk up to the queue-area camera — it will "
                      'recognize you and issue your number automatically. This '
                      'screen opens your live status the moment it does.',
                  bg: AppColors.greenLight,
                  borderColor: AppColors.green,
                  dotColor: AppColors.green,
                  textColor: AppColors.dark,
                ),
                const SizedBox(height: 10),
                PrimaryButton(
                  label: _joinBusy ? 'Cancelling…' : "Cancel — I'm not queueing",
                  outlined: true,
                  onTap: _joinBusy ? null : () => _setJoined(false),
                ),
              ] else ...[
                AlertBanner(
                  text: 'The camera will not give you a number until you join. '
                      'Tap below when you actually want to queue, then walk up '
                      'to the camera.',
                  bg: AppColors.purpleLight,
                  borderColor: AppColors.purple,
                  dotColor: AppColors.purpleDark,
                  textColor: AppColors.purpleDark,
                ),
                const SizedBox(height: 10),
                PrimaryButton(
                  label: _joinBusy ? 'Joining…' : 'Join the Queue',
                  onTap: _joinBusy ? null : () => _setJoined(true),
                ),
              ],
              const SizedBox(height: 20),

              const SectionLabel('WHAT YOU CAN DO'),
              const SizedBox(height: 8),
              const QueueListItem(
                number: '👁',
                title: 'Join, then go to the queue area',
                subtitle:
                    'Tap "Join the Queue" first, then stand where the camera '
                    'can see your face. It only issues a number to students '
                    'who have joined — walking past does nothing otherwise.',
                circBg: AppColors.purpleLight,
                circFg: AppColors.purpleDark,
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => Navigator.of(context).pushNamed('/ticket/lookup'),
                child: const QueueListItem(
                  number: '🎫',
                  title: 'Track a printed ticket',
                  subtitle: 'Holding a kiosk ticket instead? Check its status here.',
                  circBg: AppColors.purpleLight,
                  circFg: AppColors.purpleDark,
                ),
              ),
              const SizedBox(height: 28),

              PrimaryButton(
                label: 'Log Out',
                outlined: true,
                onTap: () => _logout(context),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.purpleLight,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.person, color: AppColors.purpleDark),
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
