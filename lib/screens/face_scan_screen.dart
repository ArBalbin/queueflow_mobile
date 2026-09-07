import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';

import '../services/camera_ml_kit.dart';
import '../theme/app_theme.dart';

/// Live camera preview that auto-detects a well-framed face and captures a
/// still automatically — no shutter button. Pops with the captured File, or
/// null if the user backs out.
class FaceScanScreen extends StatefulWidget {
  const FaceScanScreen({super.key});

  @override
  State<FaceScanScreen> createState() => _FaceScanScreenState();
}

class _FaceScanScreenState extends State<FaceScanScreen> {
  // Consecutive well-framed-face detections required before auto-capture —
  // filters out a fleeting/blurry/off-angle glimpse, not just any one frame.
  static const int _framesNeededToCapture = 8;
  // A detected face must fill at least this fraction of the frame's shorter
  // side to count as "close enough" — otherwise a face across the room would
  // trigger capture too eagerly.
  static const double _minFaceFraction = 0.28;

  CameraController? _controller;
  FaceDetector? _detector;
  String _status = 'Loading camera…';
  int _goodFrameStreak = 0;
  bool _isBusy = false; // guards against overlapping detector calls
  bool _captured = false;

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
      setState(() => _status = 'Position your face in the frame');
      await controller.startImageStream(_onFrame);
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Camera unavailable: $e');
    }
  }

  void _onFrame(CameraImage image) {
    if (_isBusy || _captured || _controller == null || _detector == null) return;
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
    if (!mounted || _captured) return;

    if (faces.isEmpty) {
      _goodFrameStreak = 0;
      setState(() => _status = 'Position your face in the frame');
      return;
    }

    final face = faces.reduce(
      (a, b) => a.boundingBox.width > b.boundingBox.width ? a : b,
    );
    final frameShortSide = image.width < image.height ? image.width : image.height;
    final faceFraction = face.boundingBox.width / frameShortSide;

    if (faceFraction < _minFaceFraction) {
      _goodFrameStreak = 0;
      setState(() => _status = 'Move a little closer');
      return;
    }

    _goodFrameStreak++;
    setState(() => _status = 'Hold still…');

    if (_goodFrameStreak >= _framesNeededToCapture) {
      _captured = true;
      await _captureAndReturn();
    }
  }

  Future<void> _captureAndReturn() async {
    final controller = _controller;
    if (controller == null) return;
    setState(() => _status = 'Captured!');
    try {
      await controller.stopImageStream();
      final shot = await controller.takePicture();
      if (!mounted) return;
      Navigator.of(context).pop(File(shot.path));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'Capture failed — try again';
        _captured = false;
        _goodFrameStreak = 0;
      });
    }
  }

  Future<void> _useManualCamera() async {
    // Fallback path — the user is already here because the live scan did not
    // work for them, so a silent failure would leave them stuck.
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
    if (!mounted) return;
    if (shot != null) {
      Navigator.of(context).pop(File(shot.path));
    }
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
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppColors.white),
                  ),
                  const Expanded(
                    child: Text(
                      'Scan Your Face',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40), // balances the close icon
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(200),
                  child: SizedBox(
                    width: 280,
                    height: 280,
                    child: controller != null && controller.value.isInitialized
                        ? FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: controller.value.previewSize?.height ?? 280,
                              height: controller.value.previewSize?.width ?? 280,
                              child: CameraPreview(controller),
                            ),
                          )
                        : const Center(
                            child: CircularProgressIndicator(color: AppColors.white),
                          ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: Column(
                children: [
                  Text(
                    _status,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _useManualCamera,
                    child: const Text(
                      'Trouble scanning? Take a photo manually',
                      style: TextStyle(
                        color: AppColors.purpleLight,
                        fontSize: 12,
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
