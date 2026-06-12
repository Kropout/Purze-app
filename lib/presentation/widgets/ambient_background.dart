import 'package:flutter/material.dart';
import 'dart:math' as math;

class AmbientBackground extends StatefulWidget {
  final Widget child;
  const AmbientBackground({super.key, required this.child});

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glowColor = theme.colorScheme.primary.withValues(alpha: 0.75);

    return Stack(
      children: [
        // Base surface color
        Container(color: theme.colorScheme.surface),
        
        // Animated glow
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final value = _controller.value;
            final alignmentX = -1.0 + (value * 0.4); 
            final alignmentY = -1.0 + (value * 0.2); 
            return Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(alignmentX, alignmentY),
                  radius: (1.5 + (value * 0.3)) * 0.8575,
                  colors: [
                    glowColor,
                    glowColor.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            );
          },
        ),

        // Noise Overlay
        Positioned.fill(
          child: CustomPaint(
            painter: NoisePainter(color: theme.colorScheme.onSurface),
          ),
        ),
        
        // Content
        widget.child,
      ],
    );
  }
}

class NoisePainter extends CustomPainter {
  final Color color;
  NoisePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.035)
      ..style = PaintingStyle.fill;

    final rand = math.Random(1337);
    final count = (size.width * size.height) / 1000;
    for (int i = 0; i < count; i++) {
      final x = rand.nextDouble() * size.width;
      final y = rand.nextDouble() * size.height;
      canvas.drawRect(Rect.fromLTWH(x, y, 1.2, 1.2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
