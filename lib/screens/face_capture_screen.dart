import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';

import '../services/camera_ml_kit.dart';
import '../services/queue_api.dart';
import '../services/queue_navigation.dart';
import '../services/student_session_store.dart';
import '../theme/app_theme.dart';
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

  static const List<_Pose> _poses = [
    _Pose('center', 'Look straight at the camera'),
    _Pose('turn1', 'Slowly turn your head to one side'),
    _Pose('turn2', 'Now turn your head back the other way'),
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

      _detector = FaceDetector(
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
      shot = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 90,
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

  Future<void> _submit() async {
    // Read before any await: the route arguments are what tell sign-up apart
    // from a dashboard update, and context must not be used across the gaps.
    final isSignup = _isSignup;
    setState(() {
      _isSubmitting = true;
      _status = 'Saving your face registration…';
    });
    try {
      await _controller?.dispose();
    } catch (_) {}

    try {
      await StudentSessionStore.registerFace(_photos);
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
    } on QueueApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Could not save your face registration. Try again.';
      });
    }
  }

  Future<void> _retryAfterError() async {
    setState(() {
      _errorMessage = null;
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
    _controller?.dispose();
    _detector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final borderColor = _isAligned
        ? AppColors.greenBright
        : const Color.fromARGB(255, 76, 87, 240);

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
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _poses.length; i++) ...[
                  _StepDot(done: i < _photos.length, active: i == _poseIndex),
                  if (i != _poses.length - 1) const SizedBox(width: 8),
                ],
              ],
            ),
            Expanded(
              child: Center(
                child: Container(
                  width: 292,
                  height: 292,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: borderColor, width: 4),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(200),
                    child: SizedBox(
                      width: 280,
                      height: 280,
                      child:
                          controller != null && controller.value.isInitialized
                          ? FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width:
                                    controller.value.previewSize?.height ?? 280,
                                height:
                                    controller.value.previewSize?.width ?? 280,
                                child: CameraPreview(controller),
                              ),
                            )
                          : const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              child: Column(
                children: [
                  if (_isSubmitting)
                    const CircularProgressIndicator(color: AppColors.white)
                  else ...[
                    Text(
                      _status,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color.fromARGB(255, 37, 37, 37),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Only a derived face signature is stored, never the photos '
                      'themselves.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color.fromARGB(255, 44, 44, 44),
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.red,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _retryAfterError,
                        child: const Text(
                          'Try again',
                          style: TextStyle(
                            color: AppColors.greenBright,
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _useManualCameraForCurrentPose,
                        child: const Text(
                          'Trouble scanning? Take this shot manually',
                          style: TextStyle(
                            color: AppColors.greenBright,
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
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
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done
            ? AppColors.greenBright
            : (active ? AppColors.green : AppColors.textLight),
      ),
    );
  }
}
