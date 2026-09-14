import 'dart:io';

import 'package:flutter/material.dart';

import '../services/queue_api.dart';
import '../services/queue_navigation.dart';
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
      final result = await Navigator.of(
        context,
      ).pushNamed('/student/school-id');
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
    if (hasFaceEmbedding) {
      Navigator.of(context).pushReplacementNamed('/student/home');
      return;
    }
    // An account with no face yet has not finished signing up. Mark the
    // capture screen as the sign-up flow so it ends at the login screen
    // instead of dropping a half-registered student onto the dashboard.
    Navigator.of(context).pushReplacementNamed(
      '/student/face-capture',
      arguments: faceCaptureSignupArgument,
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
    final screenHeight = MediaQuery.of(context).size.height;
    final justRegistered =
        ModalRoute.of(context)?.settings.arguments == loginRegisteredArgument;
    // Increased height ratio to give more space to the top image and logo
    final imageHeight = screenHeight * 0.44;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          // --- Top hero image with back button ---
          SizedBox(
            width: double.infinity,
            height: imageHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/img/NcfImg.png',
                    fit: BoxFit.cover,
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, top: 10),
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 16,
                          color: AppColors.dark,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- Scrollable rounded content sheet, overlapping the image ---
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -24),
              child: Container(
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo + title row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  'Welcome Back',
                                  textAlign: TextAlign.center,
                                  style: AppText.title.copyWith(
                                    color: AppColors.greenDark,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Sign in to join the queue and track your place from your phone.',
                                  textAlign: TextAlign.center,
                                  style: AppText.bodyMuted,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.green,
                            ),
                          ),
                        )
                      else ...[
                        PrimaryButton(
                          label: 'Log in with Face',
                          bg: AppColors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          fontSize: 15,
                          onTap: _handleFaceLogin,
                        ),
                        const SizedBox(height: 10),
                        PrimaryButton(
                          label: 'Sign in with Gbox',
                          outlined: true,
                          borderColor: AppColors.green,
                          fg: AppColors.greenDark,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          fontSize: 15,
                          onTap: _handleGoogleSignIn,
                        ),
                      ],

                      // Shown after sign-up returns here. Hidden as soon as an
                      // error appears, so the two never stack.
                      if (justRegistered && _errorMessage == null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.greenLight,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Text(
                            'Registration complete. Log in with your face to '
                            'confirm it recognises you, or sign in with Gbox.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: AppColors.greenDark,
                            ),
                          ),
                        ),
                      ],

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
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

                      const SizedBox(height: 20),
                      const Row(
                        children: [
                          Expanded(child: Divider(color: AppColors.borderMid)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text('New here?', style: AppText.bodyMuted),
                          ),
                          Expanded(child: Divider(color: AppColors.borderMid)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: GestureDetector(
                          onTap: _isLoading ? null : _handleGoogleSignIn,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              'Create an account',
                              style: AppText.label.copyWith(
                                color: AppColors.green,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Registering uses your NCF Gbox account.',
                        textAlign: TextAlign.center,
                        style: AppText.caption,
                      ),

                      const SizedBox(height: 16),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _isLoading
                            ? null
                            : () => Navigator.of(
                                context,
                              ).pushReplacementNamed('/ticket/lookup'),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            border: Border.all(color: AppColors.borderMid),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.confirmation_number_outlined,
                                size: 18,
                                color: AppColors.textMuted,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Just tracking a printed ticket?',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.dark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}