import 'dart:io';

import 'package:flutter/material.dart';

import '../services/queue_api.dart';
import '../services/student_api.dart';
import '../services/student_session_store.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'face_scan_screen.dart';

class StudentLoginScreen extends StatefulWidget {
  const StudentLoginScreen({super.key});

  @override
  State<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final idToken = await StudentSessionStore.getGoogleIdToken();
      if (!mounted) return;
      if (idToken == null) {
        // User cancelled the account picker.
        setState(() => _isLoading = false);
        return;
      }
      await _completeWithToken(idToken, null);
    } on QueueApiException catch (error) {
      _showError(error.message);
    } catch (e, st) {
      debugPrint('[QueuEx DEBUG] Google sign-in failed: ${e.runtimeType}: $e');
      debugPrint('[QueuEx DEBUG] stack: $st');
      _showError('Google sign-in failed. Please try again.');
    }
  }

  /// Reuses the same Google idToken for both the initial attempt and the
  /// school-ID retry, so a first-time sign-up never needs a second Google
  /// account picker just to attach the school ID.
  Future<void> _completeWithToken(String idToken, String? schoolId) async {
    try {
      final session = await StudentSessionStore.completeGoogleAuth(
        idToken,
        schoolId: schoolId,
      );
      if (!mounted) return;
      _goToNextScreen(session.profile.hasFaceEmbedding);
    } on SchoolIdRequiredException {
      if (!mounted) return;
      setState(() => _isLoading = false);
      // Plain pushNamed (no <String> type arg) — the app's `routes:` table
      // wraps every builder in an untyped MaterialPageRoute, so requesting
      // pushNamed<String> makes the Navigator's internal cast to
      // Route<String?> fail at runtime. Cast the dynamic result ourselves
      // instead.
      final result = await Navigator.of(context).pushNamed('/student/school-id');
      final enteredId = result as String?;
      if (enteredId == null || enteredId.trim().isEmpty) return;
      setState(() => _isLoading = true);
      await _completeWithToken(idToken, enteredId.trim());
    } on QueueApiException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Sign-up failed. Please try again.');
    }
  }

  Future<void> _handleFaceLogin() async {
    final photo = await Navigator.of(
      context,
    ).push<File>(MaterialPageRoute(builder: (_) => const FaceScanScreen()));
    if (photo == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final session = await StudentSessionStore.signInWithFace(photo);
      if (!mounted) return;
      _goToNextScreen(session.profile.hasFaceEmbedding);
    } on QueueApiException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Face login failed. Please try again.');
    }
  }

  void _goToNextScreen(bool hasFaceEmbedding) {
    Navigator.of(context).pushReplacementNamed(
      hasFaceEmbedding ? '/student/home' : '/student/face-capture',
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _errorMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: const QAppBar(title: 'QueuEx'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.purple,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Q',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Welcome back',
                textAlign: TextAlign.center,
                style: AppText.title,
              ),
              const SizedBox(height: 6),
              const Text(
                'Sign in to join the queue and track your place from your phone.',
                textAlign: TextAlign.center,
                style: AppText.bodyMuted,
              ),
              const SizedBox(height: 36),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.dark,
                    ),
                  ),
                )
              else ...[
                PrimaryButton(
                  label: 'Log in with Face',
                  onTap: _handleFaceLogin,
                ),
                const SizedBox(height: 10),
                PrimaryButton(
                  label: 'Sign in with Gbox',
                  outlined: true,
                  onTap: _handleGoogleSignIn,
                ),
              ],

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: AppColors.redLight,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: AppColors.redDark,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 28),
              const Row(
                children: [
                  Expanded(child: Divider(color: AppColors.borderMid)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('NEW HERE?', style: AppText.overline),
                  ),
                  Expanded(child: Divider(color: AppColors.borderMid)),
                ],
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Create an account',
                outlined: true,
                borderColor: AppColors.purple,
                fg: AppColors.purpleDark,
                onTap: _isLoading ? null : _handleGoogleSignIn,
              ),
              const SizedBox(height: 8),
              const Text(
                'Registering uses your NCF Gbox account.',
                textAlign: TextAlign.center,
                style: AppText.caption,
              ),

              const Spacer(),
              Center(
                child: GestureDetector(
                  onTap: _isLoading
                      ? null
                      : () => Navigator.of(
                          context,
                        ).pushReplacementNamed('/ticket/lookup'),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Just tracking a printed ticket?',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textLight,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}
