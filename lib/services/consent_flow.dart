import 'package:flutter/material.dart';

import '../screens/consent_screen.dart';
import 'privacy_notice.dart';
import 'student_session_store.dart';

/// Shows the data-privacy notice to a signed-in student who has not agreed to
/// the current version (accounts created before the notice existed, or after
/// its text changed). Returns true when the student may continue. Declining
/// signs them out: without consent the system cannot process their face.
Future<bool> ensureStudentConsent(BuildContext context) async {
  final profile = StudentSessionStore.profile;
  if (profile == null || !profile.consentRequired) return true;

  final agreed = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => const ConsentScreen()),
  );
  if (agreed != true) {
    await StudentSessionStore.logout();
    return false;
  }
  await StudentSessionStore.giveConsent(kConsentVersion);
  return true;
}

/// Opens the notice for reading only (from the Profile screen).
Future<void> showPrivacyNotice(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const ConsentScreen(readOnly: true)),
  );
}

const String kConsentDeclinedMessage =
    'You need to agree to the privacy notice to use QueuEx. You can still take '
    'a printed ticket from the office kiosk.';
