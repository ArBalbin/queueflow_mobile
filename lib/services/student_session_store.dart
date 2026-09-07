import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/student_models.dart';
import 'google_auth_config.dart';
import 'queue_api.dart';
import 'student_api.dart';

/// Persistent student login (Google sign-in or face login), separate from
/// QueueSessionStore above which tracks a single ticket lookup session.
/// This one survives app restarts via shared_preferences.
class StudentSessionStore {
  static final StudentApiClient api = StudentApiClient();
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email'],
    serverClientId: GoogleAuthConfig.serverClientId,
  );

  static const _tokenKey = 'student_session_token';

  static String? _sessionToken;
  static StudentProfile? profile;

  static bool get isLoggedIn => _sessionToken != null;
  static String? get sessionToken => _sessionToken;

  /// Call once at app startup. Restores a saved session if the token is
  /// still valid server-side; clears it silently if not.
  static Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_tokenKey);
    if (saved == null || saved.isEmpty) return false;

    try {
      profile = await api.getMe(saved);
      _sessionToken = saved;
      return true;
    } catch (_) {
      await prefs.remove(_tokenKey);
      return false;
    }
  }

  static Future<void> _persist(StudentSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, session.sessionToken);
    _sessionToken = session.sessionToken;
    profile = session.profile;
  }

  /// Opens the Google account picker and returns the ID token. Returns null
  /// if the user cancelled. This only talks to Google — call
  /// completeGoogleAuth() with the result to actually reach our backend.
  ///
  /// Split out from completeGoogleAuth() so a first-time sign-up (which
  /// needs a school ID) never has to re-prompt Google a second time just to
  /// retry with that ID attached — the same token is reused for both calls.
  static Future<String?> getGoogleIdToken() async {
    // Drop any cached Google account before prompting. Without this,
    // signIn() silently returns whoever was picked last instead of showing
    // the chooser — so a student who picked a personal (non-Gbox) account
    // by mistake would keep re-sending that same rejected account on every
    // retry, with no way to switch, short of reinstalling the app.
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Nothing cached, or the plugin had nothing to clear — carry on.
    }

    final account = await _googleSignIn.signIn();
    if (account == null) return null;

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null) {
      throw const QueueApiException(
        'Google sign-in did not return a token. Please try again.',
      );
    }
    return idToken;
  }

  /// Throws SchoolIdRequiredException on a first-time sign-in — call again
  /// with the same idToken plus schoolId once you have it.
  static Future<StudentSession> completeGoogleAuth(
    String idToken, {
    String? schoolId,
  }) async {
    final session = await api.googleAuth(idToken: idToken, schoolId: schoolId);
    await _persist(session);
    return session;
  }

  static Future<StudentSession> signInWithFace(File photo) async {
    final session = await api.faceLogin(photo);
    await _persist(session);
    return session;
  }

  static Future<void> registerFace(List<File> photos) async {
    final token = _sessionToken;
    if (token == null) {
      throw const QueueApiException('Not logged in.');
    }
    await api.registerFace(photos, token);
    profile = await api.getMe(token);
  }

  /// Signs the student out. Deliberately cannot throw: logging out must
  /// always succeed locally, even with no network and even if storage
  /// misbehaves — otherwise the user is stranded on a screen they asked to
  /// leave, still holding a session they believe is closed.
  static Future<void> logout() async {
    final token = _sessionToken;

    // Clear in-memory state FIRST, so the user is logged out of this session
    // regardless of what the remote/storage steps below do.
    _sessionToken = null;
    profile = null;

    if (token != null) {
      try {
        await api.logout(token);
      } catch (_) {
        // Best-effort: the server session expires on its own.
      }
    }
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Nothing cached, or Play Services unavailable.
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    } catch (_) {
      // Token stays on disk but is already cleared in memory; restoreSession()
      // validates against the backend on next launch and drops it if stale.
    }
  }
}
