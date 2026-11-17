import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';

import '../services/camera_ml_kit.dart';
import '../services/consent_flow.dart';
import '../services/student_api.dart';
import '../services/queue_api.dart';
import '../services/queue_navigation.dart';
import '../services/student_session_store.dart';
import '../theme/app_theme.dart';
import '../widgets/face_scan_widgets.dart';
import '../widgets/shared_widgets.dart';

class _Pose {
  final String key;
  final String prompt;
  const _Pose(this.key, this.prompt);
}

class FaceCaptureScreen extends StatefulWidget {
  const FaceCaptureScreen({super.key});

  @override
  State<FaceCaptureScreen> createState() => _FaceCaptureScreenState();
}

class _FaceCaptureScreenState extends State<FaceCaptureScreen> {
  static const int _framesNeededToCapture = 8;
  static const double _minFaceFraction = 0.28;
  static const double _centerYawMax = 10;
  static const double _turnYawMin = 18;
  static const int _darkLumaThreshold = 60;
  static const int _brightLumaThreshold = 210;

  /// Tries before the student is asked to send again. A failed send is
  /// usually the connection, and registering the same photos twice is
  /// harmless: the second simply replaces the first.
  static const int _maxAttempts = 2;

  // "Turn your head back the other way" was read as "look behind you" in the
  // user acceptance test; the third prompt now says "other side".
  static const List<_Pose> _poses = [
    _Pose('center', 'Look straight at the camera'),
    _Pose('turn1', 'Slowly turn your head to the left or right'),
    _Pose('turn2', 'Now turn your head to the other side'),
  ];

  CameraController? _controller;
  FaceDetector? _detector;
  final List<File> _photos = [];
  int _poseIndex = 0;
  double _firstTurnSign = 0;
  String _status = 'Loading camera…';
  int _goodFrameStreak = 0;
  bool _isBusy = false;
  bool _capturing = false;
  bool _isSubmitting = false;
  bool _isAligned = false;
  String? _errorMessage;

  // Saving: how much of the upload is sent, whether the server is checking
  // the face, which try this is, and seconds since saving began.
  double _sent = 0;
  bool _checking = false;
  int _attempt = 1;
  int _elapsed = 0;
  Timer? _ticker;

  /// After a send that got no answer, the same photos can be sent again
  /// without scanning the face again.
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    try {
      final cameras = await availableCameras();
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _detector ??= FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.fast,
          enableTracking: false,
        ),
      );

      final controller = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      _controller = controller;
      setState(() => _status = _poses[_poseIndex].prompt);
      await controller.startImageStream(_onFrame);
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Camera unavailable: $e');
    }
  }

  void _onFrame(CameraImage image) {
    if (_isBusy ||
        _capturing ||
        _isSubmitting ||
        _controller == null ||
        _detector == null) {
      return;
    }
    _isBusy = true;
    _processFrame(image).whenComplete(() => _isBusy = false);
  }

  Future<void> _processFrame(CameraImage image) async {
    final inputImage = toMlKitInputImage(image, _controller!.description);
    if (inputImage == null) return;

    List<Face> faces;
    try {
      faces = await _detector!.processImage(inputImage);
    } catch (_) {
      return;
    }
    if (!mounted || _capturing || _isSubmitting) return;

    final luma = averageLuma(image);
    if (luma != null && luma < _darkLumaThreshold) {
      _markNotAligned('Too dark — move somewhere brighter');
      return;
    }
    if (luma != null && luma > _brightLumaThreshold) {
      _markNotAligned('Too bright — reduce glare or backlight');
      return;
    }

    if (faces.isEmpty) {
      _markNotAligned(_poses[_poseIndex].prompt);
      return;
    }

    final face = faces.reduce(
      (a, b) => a.boundingBox.width > b.boundingBox.width ? a : b,
    );
    final frameShortSide = image.width < image.height
        ? image.width
        : image.height;
    final faceFraction = face.boundingBox.width / frameShortSide;

    if (faceFraction < _minFaceFraction) {
      _markNotAligned('Move a little closer');
      return;
    }

    final yaw = face.headEulerAngleY ?? 0;
    final pose = _poses[_poseIndex];
    final bool poseMatches;
    switch (pose.key) {
      case 'center':
        poseMatches = yaw.abs() <= _centerYawMax;
      case 'turn1':
        poseMatches = yaw.abs() >= _turnYawMin;
      default:
        poseMatches =
            yaw.abs() >= _turnYawMin &&
            (_firstTurnSign == 0 || yaw.sign != _firstTurnSign);
    }

    if (!poseMatches) {
      _markNotAligned(pose.prompt);
      return;
    }

    _goodFrameStreak++;
    setState(() {
      _isAligned = true;
      _status = 'Hold still…';
    });

    if (_goodFrameStreak >= _framesNeededToCapture) {
      if (pose.key == 'turn1') _firstTurnSign = yaw.sign;
      _capturing = true;
      await _captureCurrentPose();
    }
  }

  void _markNotAligned(String status) {
    _goodFrameStreak = 0;
    setState(() {
      _isAligned = false;
      _status = status;
    });
  }

  Future<void> _captureCurrentPose() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      await controller.stopImageStream();
      final shot = await controller.takePicture();
      _photos.add(File(shot.path));

      if (_poseIndex >= _poses.length - 1) {
        await _submit();
        return;
      }

      setState(() {
        _poseIndex++;
        _goodFrameStreak = 0;
        _capturing = false;
        _isAligned = false;
        _status = _poses[_poseIndex].prompt;
      });
      await controller.startImageStream(_onFrame);
    } catch (_) {
      setState(() {
        _capturing = false;
        _goodFrameStreak = 0;
        _status = 'Capture failed — hold still and try again';
      });
      try {
        await controller.startImageStream(_onFrame);
      } catch (_) {}
    }
  }

  Future<void> _useManualCameraForCurrentPose() async {
    final XFile? shot;
    try {
      // A phone camera's full-size photo can be several megabytes, slow to
      // upload on a weak connection; the face check needs far less.
      shot = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
        maxWidth: 1080,
        maxHeight: 1080,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Could not open the camera app: $e');
      return;
    }
    if (shot == null || !mounted) return;
    _photos.add(File(shot.path));

    if (_poseIndex >= _poses.length - 1) {
      await _submit();
      return;
    }
    setState(() {
      _poseIndex++;
      _goodFrameStreak = 0;
      _status = _poses[_poseIndex].prompt;
    });
  }

  /// True when this capture is the last step of sign-up rather than a
  /// signed-in student updating their face from the dashboard.
  bool get _isSignup =>
      ModalRoute.of(context)?.settings.arguments == faceCaptureSignupArgument;

  /// Leaves the screen without saving a face.
  ///
  /// During sign-up this signs the student out and returns to login: backing
  /// out must not leave a half-registered account sitting on the dashboard,
  /// which is the outcome sign-up is meant to avoid. Their account keeps its
  /// school ID, so signing in again resumes straight at this screen.
  Future<void> _leave() async {
    if (_isSignup) {
      await StudentSessionStore.logout();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/student/login', (_) => false);
      return;
    }
    Navigator.of(context).pushReplacementNamed('/student/home');
  }

  void _startTicker() {
    _ticker?.cancel();
    _elapsed = 0;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed++);
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  /// Sends the photos, showing how far the upload has got and then that the
  /// face is being checked. A send that gets no answer is tried again on its
  /// own; if that fails too, the student can send the same photos again
  /// instead of scanning their face again.
  Future<void> _submit() async {
    // Read before any await: the route arguments are what tell sign-up apart
    // from a dashboard update, and context must not be used across the gaps.
    final isSignup = _isSignup;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _canResend = false;
      _sent = 0;
      _checking = false;
      _attempt = 1;
    });
    _startTicker();
    final controller = _controller;
    _controller = null;
    try {
      await controller?.dispose();
    } catch (_) {}

    for (var attempt = 1; ; attempt++) {
      if (!mounted) return;
      setState(() {
        _attempt = attempt;
        _sent = 0;
        _checking = false;
      });
      try {
        await StudentSessionStore.registerFace(
          _photos,
          onProgress: (sent) {
            if (!mounted) return;
            setState(() {
              _sent = sent;
              _checking = sent >= 1;
            });
          },
        );
        break;
      } on ConsentRequiredException {
        _stopTicker();
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        if (!await ensureStudentConsent(context) && mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/student/login', (_) => false);
          return;
        }
        if (!mounted) return;
        setState(() {
          _canResend = true;
          _errorMessage = 'Thank you. Tap Send again to register your face.';
        });
        return;
      } on QueueApiException catch (error) {
        // No status code: the server never answered (slow or lost
        // connection), so the same photos are worth sending again. With a
        // status code it did answer, e.g. the face was not clear enough,
        // and only new photos will help.
        final noAnswer = error.statusCode == null;
        if (noAnswer && attempt < _maxAttempts) {
          await Future<void>.delayed(Duration(seconds: 2 * attempt));
          continue;
        }
        _stopTicker();
        if (!mounted) return;
        setState(() {
          _isSubmitting = false;
          _canResend = noAnswer;
          _errorMessage = error.message;
        });
        return;
      } catch (_) {
        _stopTicker();
        if (!mounted) return;
        setState(() {
          _isSubmitting = false;
          _canResend = true;
          _errorMessage = 'Could not save your face registration.';
        });
        return;
      }
    }

    _stopTicker();
    if (!mounted) return;
    if (isSignup) {
      // Registration ends at the login screen, signed out, so the student
      // logs in for real — and a face login immediately afterwards confirms
      // the capture they just saved actually recognises them. The route
      // stack is cleared so back cannot return here or to the dashboard.
      await StudentSessionStore.logout();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/student/login',
        (_) => false,
        arguments: loginRegisteredArgument,
      );
      return;
    }
    Navigator.of(context).pushReplacementNamed('/student/home');
  }

  /// Scans the face again from the first pose.
  Future<void> _retakePhotos() async {
    setState(() {
      _errorMessage = null;
      _canResend = false;
      _photos.clear();
      _poseIndex = 0;
      _firstTurnSign = 0;
      _goodFrameStreak = 0;
      _capturing = false;
      _isSubmitting = false;
      _isAligned = false;
      _status = 'Loading camera…';
    });
    await _setup();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _controller?.dispose();
    _detector?.close();
    super.dispose();
  }

  String get _promptText {
    if (_isSubmitting) {
      return _checking ? 'Checking your face…' : 'Sending your photos…';
    }
    if (_errorMessage != null) {
      return _canResend ? 'Your photos were not sent' : 'Please scan your face again';
    }
    return _status;
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final preview =
        !_isSubmitting && controller != null && controller.value.isInitialized
        ? controller
        : null;
    final holdProgress = _isAligned && !_isSubmitting && _errorMessage == null
        ? _goodFrameStreak / _framesNeededToCapture
        : null;

    return Scaffold(
      backgroundColor: AppColors.greenLight,
      appBar: QAppBar(
        title: 'Register Your Face',
        showBack: true,
        onBack: _leave,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _poses.length; i++) ...[
                  _StepDot(done: i < _photos.length, active: i == _poseIndex),
                  if (i != _poses.length - 1) const SizedBox(width: 10),
                ],
              ],
            ),
            const SizedBox(height: 12),
            FaceScanPrompt(
              text: _promptText,
              step: _isSubmitting || _errorMessage != null
                  ? null
                  : 'STEP ${_poseIndex + 1} OF ${_poses.length}',
              good: _isAligned && !_isSubmitting,
            ),
            Expanded(
              child: Center(
                child: FaceCameraCircle(
                  progress: holdProgress,
                  borderColor: _isAligned
                      ? AppColors.greenBright
                      : const Color.fromARGB(255, 76, 87, 240),
                  child: preview != null
                      ? FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: preview.value.previewSize?.height ?? 280,
                            height: preview.value.previewSize?.width ?? 280,
                            child: CameraPreview(preview),
                          ),
                        )
                      : Center(
                          child: _isSubmitting
                              ? const Icon(Icons.cloud_upload_outlined,
                                  size: 72, color: AppColors.green)
                              : const CircularProgressIndicator(
                                  color: AppColors.green,
                                ),
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: _isSubmitting
                  ? _SaveProgress(
                      sent: _sent,
                      checking: _checking,
                      attempt: _attempt,
                      maxAttempts: _maxAttempts,
                      elapsed: _elapsed,
                    )
                  : _errorMessage != null
                  ? _SaveError(
                      message: _errorMessage!,
                      canResend: _canResend,
                      onResend: _submit,
                      onRetake: _retakePhotos,
                    )
                  : Column(
                      children: [
                        const Text(
                          'Only a derived face signature is stored, never the '
                          'photos themselves.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color.fromARGB(255, 44, 44, 44),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _useManualCameraForCurrentPose,
                          child: const Text(
                            'Trouble scanning? Take this shot manually',
                            style: TextStyle(
                              color: AppColors.green,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Progress while the photos are sent and the face is checked.
class _SaveProgress extends StatelessWidget {
  final double sent;
  final bool checking;
  final int attempt;
  final int maxAttempts;
  final int elapsed;

  const _SaveProgress({
    required this.sent,
    required this.checking,
    required this.attempt,
    required this.maxAttempts,
    required this.elapsed,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (sent * 100).clamp(0, 100).round();
    final String detail;
    if (attempt > 1) {
      detail = 'The connection is slow — trying again ($attempt of $maxAttempts).';
    } else if (checking) {
      detail = 'This can take up to a minute when many students are '
          'registering. Please keep the app open.';
    } else {
      detail = 'Sent $percent%';
    }
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            // Determinate while sending; moving while the server checks.
            value: checking ? null : sent,
            minHeight: 10,
            color: AppColors.greenBright,
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          detail,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$elapsed s',
          style: const TextStyle(color: Color(0xFF555555), fontSize: 13),
        ),
      ],
    );
  }
}

/// What went wrong, and what the student can do about it.
class _SaveError extends StatelessWidget {
  final String message;
  final bool canResend;
  final VoidCallback onResend;
  final VoidCallback onRetake;

  const _SaveError({
    required this.message,
    required this.canResend,
    required this.onResend,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.red,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 14),
        if (canResend) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onResend,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Send again',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextButton(
          onPressed: onRetake,
          child: Text(
            canResend ? 'Retake photos instead' : 'Retake photos',
            style: const TextStyle(
              color: AppColors.green,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  final bool done;
  final bool active;
  const _StepDot({required this.done, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done
            ? AppColors.greenBright
            : (active ? AppColors.green : AppColors.textLight),
      ),
    );
  }
}
