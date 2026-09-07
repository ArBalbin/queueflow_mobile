import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Converts a live [CameraImage] frame into the format ML Kit's on-device
/// face detector expects. Shared by every screen that runs a real-time
/// face-guided camera preview (face login, face registration).
InputImage? toMlKitInputImage(CameraImage image, CameraDescription camera) {
  final sensorOrientation = camera.sensorOrientation;
  final rotation = InputImageRotationValue.fromRawValue(sensorOrientation) ??
      InputImageRotation.rotation0deg;

  if (Platform.isAndroid) {
    // NV21: single plane with interleaved Y + VU already laid out by the
    // camera plugin when imageFormatGroup is nv21 on Android.
    final format = InputImageFormatValue.fromRawValue(image.format.raw) ??
        InputImageFormat.nv21;
    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  // iOS: bgra8888, also a single plane.
  final plane = image.planes.first;
  return InputImage.fromBytes(
    bytes: plane.bytes,
    metadata: InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: InputImageFormat.bgra8888,
      bytesPerRow: plane.bytesPerRow,
    ),
  );
}

/// Average luma (0-255) of an NV21 frame's Y-plane, sampled at a stride for
/// speed. Returns null on iOS (bgra8888 isn't plain luma) or a malformed
/// frame. Used to prompt "too dark" / "too bright" during guided capture.
int? averageLuma(CameraImage image) {
  if (!Platform.isAndroid) return null;
  final bytes = image.planes.first.bytes;
  final ySize = image.width * image.height;
  if (ySize <= 0 || ySize > bytes.length) return null;
  const sampleStride = 97; // arbitrary odd stride for a cheap, unbiased sample
  var sum = 0;
  var count = 0;
  for (var i = 0; i < ySize; i += sampleStride) {
    sum += bytes[i];
    count++;
  }
  if (count == 0) return null;
  return (sum / count).round();
}
