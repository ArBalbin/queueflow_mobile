import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/queue_waiting_screen.dart';
import 'screens/youre_next_screen.dart';
import 'screens/service_complete_screen.dart';
import 'screens/exit_notification_screen.dart';
import 'screens/serving_screen.dart';
import 'screens/skipped_screen.dart';
import 'screens/history_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/help_screen.dart';
import 'screens/student_login_screen.dart';
import 'screens/school_id_screen.dart';
import 'screens/face_capture_screen.dart';
import 'screens/student_home_screen.dart';
import 'services/consent_flow.dart';
import 'services/idle_logout.dart';
import 'services/queue_navigation.dart';
import 'services/queue_session_store.dart';
import 'services/student_session_store.dart';

/// Lets the idle sign-out return to the login screen from wherever the
/// student is when the app is reopened.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  IdleLogout(appNavigatorKey).start();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF1A1A2E),
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const QueueFlowApp());
}

class QueueFlowApp extends StatelessWidget {
  const QueueFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'QueuEx',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: '/',
      routes: {
        '/': (_) => const _BootstrapScreen(),
        '/student/login': (_) => const StudentLoginScreen(),
        '/student/school-id': (_) => const SchoolIdScreen(),
        '/student/face-capture': (_) => const FaceCaptureScreen(),
        '/student/home': (_) => const StudentHomeScreen(),
        '/ticket/lookup': (_) => LoginScreen(),
        '/queue/waiting': (_) => const QueueWaitingScreen(),
        '/queue/next': (_) => const YoureNextScreen(),
        '/queue/complete': (_) => const ServiceCompleteScreen(),
        '/queue/exit': (_) => const ExitNotificationScreen(),
        '/queue/skipped': (_) => const SkippedScreen(),
        '/queue/serving': (_) => const ServingScreen(),
        '/history': (_) => const HistoryScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/help': (_) => HelpScreen(),
      },
    );
  }
}

/// Decides where to land on launch: a still-valid saved student session
/// skips straight to home (or face capture, if that step is incomplete);
/// failing that, a guest who was tracking a printed ticket resumes on their
/// live status screen; otherwise the student sign-in screen.
class _BootstrapScreen extends StatefulWidget {
  const _BootstrapScreen();

  @override
  State<_BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends State<_BootstrapScreen>
    with SingleTickerProviderStateMixin {
  // Long enough for the logo to register, short enough not to be a wait.
  static const _minimumShown = Duration(milliseconds: 1200);

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  @override
  void initState() {
    super.initState();
    _decide();
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  Future<void> _decide() async {
    final results = await Future.wait([
      StudentSessionStore.restoreSession(),
      Future<void>.delayed(_minimumShown),
    ]);
    final restored = results.first as bool;
    if (!mounted) return;

    // Reopening the app after it sat unused ends the saved session, unless
    // the student is in the queue.
    if (restored && await IdleLogout.shouldSignOut()) {
      await IdleLogout.signOut();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        '/student/login',
        arguments: loginIdleArgument,
      );
      return;
    }
    if (restored) await IdleLogout.markActive();
    if (!mounted) return;

    if (restored && !await ensureStudentConsent(context)) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/student/login');
      return;
    }
    if (!mounted) return;

    if (restored) {
      final hasFace = StudentSessionStore.profile?.hasFaceEmbedding ?? false;
      // A restored session with no face is a sign-up the student abandoned
      // before capturing their face (app closed mid-registration). Resume it
      // as sign-up, so it too finishes at the login screen.
      Navigator.of(context).pushReplacementNamed(
        hasFace ? '/student/home' : '/student/face-capture',
        arguments: hasFace ? null : faceCaptureSignupArgument,
      );
      return;
    }

    // Not signed in — but a guest may have been mid-way through tracking a
    // printed ticket before the app was closed.
    final ticketRestored = await QueueSessionStore.restoreSession();
    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed(
      ticketRestored ? routeForCurrentQueue() : '/student/login',
    );
  }

  /// The loading screen: the same logo, size and place as Android's start
  /// screen (res/drawable/launch_background.xml), so the hand-over from
  /// Android to the app does not jump.
  @override
  Widget build(BuildContext context) {
    final fadeIn = CurvedAnimation(parent: _intro, curve: Curves.easeOut);
    return Scaffold(
      backgroundColor: AppColors.green,
      body: Stack(
        children: [
          Center(
            child: Image.asset(
              'assets/img/Logo.png',
              width: 200,
              semanticLabel: 'QueuEx',
            ),
          ),
          Align(
            alignment: const Alignment(0, 0.3),
            child: FadeTransition(
              opacity: fadeIn,
              child: const Text(
                'Your cashier queue, on your phone',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xDDFFFFFF),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 48,
            child: FadeTransition(
              opacity: fadeIn,
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.white,
                    ),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Naga College Foundation',
                    style: TextStyle(fontSize: 12, color: Color(0x99FFFFFF)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
