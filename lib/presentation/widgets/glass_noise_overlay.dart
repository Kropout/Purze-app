import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';

/// A painter that draws subtle noise to simulate a grain/texture overlay
class NoisePainter extends CustomPainter {
  final double opacity;
  final Random _random = Random(42); // Fixed seed for consistent noise

  NoisePainter({this.opacity = 0.05});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..strokeWidth = 1.0;

    // Draw random dots across the canvas
    for (int i = 0; i < (size.width * size.height / 100).toInt(); i++) {
      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * size.height;
      canvas.drawPoints(PointMode.points, [Offset(x, y)], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A wrapper that applies a subtle noise texture over any child
class GlassNoiseOverlay extends StatelessWidget {
  final Widget child;
  final BorderRadius? borderRadius;

  const GlassNoiseOverlay({super.key, required this.child, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: borderRadius ?? BorderRadius.zero,
              child: CustomPaint(
                painter: NoisePainter(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
