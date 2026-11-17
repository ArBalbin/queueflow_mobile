import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The instruction shown above the camera circle while a face is scanned.
///
/// Large and on top, where the student is already looking. In the user
/// acceptance test the small line under the circle was hard to read with the
/// phone held out at arm's length, and students asked for it bigger and above
/// the circle.
class FaceScanPrompt extends StatelessWidget {
  final String text;
  final String? step;
  final bool good;

  const FaceScanPrompt({
    super.key,
    required this.text,
    this.step,
    this.good = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: good ? AppColors.greenBright : Colors.white,
          width: 3,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (step != null) ...[
            Text(
              step!,
              style: const TextStyle(
                color: AppColors.green,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

/// The round camera preview, with a ring that fills while the face is held in
/// position, so the student can see the photo is about to be taken.
class FaceCameraCircle extends StatelessWidget {
  final Widget child;

  /// 0 to 1 while holding still; null shows no ring.
  final double? progress;
  final Color borderColor;

  const FaceCameraCircle({
    super.key,
    required this.child,
    this.progress,
    this.borderColor = AppColors.greenBright,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 292,
            height: 292,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(200),
              child: SizedBox(width: 280, height: 280, child: child),
            ),
          ),
          if (progress != null)
            SizedBox(
              width: 300,
              height: 300,
              child: CircularProgressIndicator(
                value: progress!.clamp(0.0, 1.0),
                strokeWidth: 7,
                color: AppColors.greenBright,
                backgroundColor: Colors.white.withValues(alpha: 0.5),
              ),
            ),
        ],
      ),
    );
  }
}
