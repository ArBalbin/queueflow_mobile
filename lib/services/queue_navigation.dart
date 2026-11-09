import 'package:flutter/widgets.dart';

import '../models/queue_models.dart';
import 'queue_session_store.dart';
import 'student_session_store.dart';

/// Route argument marking face capture as the final step of sign-up, as
/// opposed to a signed-in student setting up or replacing their face from the
/// dashboard. The two must end differently: sign-up ends at the login screen,
/// a dashboard update ends back on the dashboard. Without the marker the
/// capture screen cannot tell them apart, and logging out at the end of every
/// capture would sign out a student who only wanted to update their photo.
const String faceCaptureSignupArgument = 'signup';

/// Route argument telling the login screen that a registration has just
/// finished, so it can say so rather than reappearing with no explanation.
const String loginRegisteredArgument = 'registered';

/// Route argument telling the login screen the student was signed out for
/// leaving the app unused, so the return to sign-in is explained.
const String loginIdleArgument = 'idle';

String routeForQueueSnapshot(QueueSnapshot snapshot) {
  final status = snapshot.status;
  // Checked first: a skipped ticket is over too, but for a different reason,
  // and used to fall through to the waiting screen with no explanation.
  if (status.isNoShow) return '/queue/skipped';
  if (status.isDone) return '/queue/exit';
  // Called to a window. With several windows open this happens at positions
  // 2 and 3 as well, which used to show "Waiting in line".
  if (status.isBeingServed) return '/queue/serving';
  if (status.isNext) return '/queue/next';
  return '/queue/waiting';
}

String routeForCurrentQueue() {
  final snapshot = QueueSessionStore.latestSnapshot;
  if (snapshot != null) return routeForQueueSnapshot(snapshot);
  if (QueueSessionStore.hasSession) return '/queue/waiting';
  // No ticket being tracked. A signed-in student belongs on their own
  // dashboard — only a guest, who has no account to go back to, lands on
  // the ticket-lookup form.
  return backDestination();
}

/// Where a screen's back button should land. Most flows navigate by
/// *replacing* the route (poll-driven queue-status transitions especially),
/// so there's usually no stack to pop — back has to be an explicit
/// destination: a signed-in student goes home, a guest tracking a printed
/// ticket goes back to the lookup screen.
String backDestination() {
  return StudentSessionStore.isLoggedIn ? '/student/home' : '/ticket/lookup';
}

/// Navigates to [backDestination] by replacement, so back buttons never
/// stack up another copy of the destination screen.
void goBack(BuildContext context) {
  Navigator.of(context).pushReplacementNamed(backDestination());
}

String routeForBottomNavIndex(int index) {
  return switch (index) {
    0 => routeForCurrentQueue(),
    1 => '/history',
    2 => '/profile',
    3 => '/help',
    _ => routeForCurrentQueue(),
  };
}
