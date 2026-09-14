import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  late final MobileScannerController _controller;
  bool _isReturning = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      formats: const [BarcodeFormat.qrCode],
      detectionSpeed: DetectionSpeed.normal,
      autoZoom: true,
    );
  }

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  void _handleDetect(BarcodeCapture capture) {
    if (_isReturning) return;

    String? rawValue;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue ?? barcode.displayValue;
      if (value != null && value.trim().isNotEmpty) {
        rawValue = value;
        break;
      }
    }

    if (rawValue == null) return;

    _isReturning = true;
    unawaited(_controller.stop());
    if (mounted) Navigator.pop(context, rawValue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: QAppBar(
        title: 'Scan Ticket QR',
        showBack: true,
        onBack: () => Navigator.of(context).pop(),
        actions: [
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (context, state, _) {
              final torchAvailable = state.torchState != TorchState.unavailable;
              final torchOn = state.torchState == TorchState.on;
              return IconButton(
                tooltip: 'Flashlight',
                color: AppColors.white,
                onPressed: torchAvailable
                    ? () => unawaited(_controller.toggleTorch())
                    : null,
                icon: Icon(
                  torchOn
                      ? Icons.flashlight_on_rounded
                      : Icons.flashlight_off_rounded,
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _handleDetect),
          CustomPaint(painter: _ScannerOverlayPainter()),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              minimum: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xCC1A1A2E),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0x66047857)),
                ),
                child: const Text(
                  'Point the camera at the QueuEx QR code on your ticket.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 11,
                    height: 1.35,
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

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scanSize = size.width * 0.68;
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.42),
      width: scanSize,
      height: scanSize,
    );

    final shade = Paint()..color = const Color(0x99000000);
    final cutout = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(18)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(cutout, shade);

    final border = Paint()
      ..color = AppColors.green
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const radius = Radius.circular(18);
    final rrect = RRect.fromRectAndRadius(rect, radius);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke,
    );

    const corner = 38.0;
    canvas.drawLine(
      rect.topLeft,
      rect.topLeft + const Offset(corner, 0),
      border,
    );
    canvas.drawLine(
      rect.topLeft,
      rect.topLeft + const Offset(0, corner),
      border,
    );
    canvas.drawLine(
      rect.topRight,
      rect.topRight + const Offset(-corner, 0),
      border,
    );
    canvas.drawLine(
      rect.topRight,
      rect.topRight + const Offset(0, corner),
      border,
    );
    canvas.drawLine(
      rect.bottomLeft,
      rect.bottomLeft + const Offset(corner, 0),
      border,
    );
    canvas.drawLine(
      rect.bottomLeft,
      rect.bottomLeft + const Offset(0, -corner),
      border,
    );
    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight + const Offset(-corner, 0),
      border,
    );
    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight + const Offset(0, -corner),
      border,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
