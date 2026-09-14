import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/queue_waiting_screen.dart';
import 'screens/youre_next_screen.dart';
import 'screens/service_complete_screen.dart';
import 'screens/exit_notification_screen.dart';
import 'screens/no_show_warning_screen.dart';
import 'screens/history_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/help_screen.dart';
import 'screens/student_login_screen.dart';
import 'screens/school_id_screen.dart';
import 'screens/face_capture_screen.dart';
import 'screens/student_home_screen.dart';
import 'services/queue_navigation.dart';
import 'services/queue_session_store.dart';
import 'services/student_session_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      title: 'QueuEx',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: '/student/home',
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
        '/queue/noshow': (_) => const NoShowWarningScreen(),
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

class _BootstrapScreenState extends State<_BootstrapScreen> {
  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    final restored = await StudentSessionStore.restoreSession();
    if (!mounted) return;

    if (restored) {
      final hasFace = StudentSessionStore.profile?.hasFaceEmbedding ?? false;
      Navigator.of(context).pushReplacementNamed(
        hasFace ? '/student/home' : '/student/face-capture',
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

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.dark,
      body: Center(child: CircularProgressIndicator(color: AppColors.white)),
    );
  }
}
