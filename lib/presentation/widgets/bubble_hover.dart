import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class BubbleHover extends StatefulWidget {
  final Widget child;
  final bool enableScale;
  final bool enableGlow;
  final double borderRadius;
  final VoidCallback? onTap;

  const BubbleHover({
    super.key,
    required this.child,
    this.enableScale = true,
    this.enableGlow = true,
    this.borderRadius = 16,
    this.onTap,
  });

  @override
  State<BubbleHover> createState() => _BubbleHoverState();
}

class _BubbleHoverState extends State<BubbleHover>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack, // springy bubble kinetics
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleHover(bool isHovered) {
    if (isHovered) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.enableScale ? 1.0 + (0.03 * _animation.value) : 1.0;
    
    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.scale(
              scale: scale,
              child: Stack(
                clipBehavior: Clip.antiAlias,
                children: [
                  // 1. Shadow Glow Layer
                  if (widget.enableGlow)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(widget.borderRadius),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(
                                alpha: 0.05 + 0.12 * _animation.value,
                              ),
                              blurRadius: 16 + 14 * _animation.value,
                              spreadRadius: -2 + 4 * _animation.value,
                            ),
                            BoxShadow(
                              color: AppColors.secondary.withValues(
                                alpha: 0.02 + 0.08 * _animation.value,
                              ),
                              blurRadius: 24 + 16 * _animation.value,
                              spreadRadius: -4 + 6 * _animation.value,
                            ),
                          ],
                        ),
                      ),
                    ),

                  // 2. Child Content Layer
                  ClipRRect(
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    child: widget.child,
                  ),

                  // 3. Specular Highlight (Bubble Reflection Gloss)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(widget.borderRadius),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(
                                alpha: 0.08 + 0.12 * _animation.value,
                              ),
                              Colors.white.withValues(alpha: 0.01),
                              Colors.transparent,
                              Colors.white.withValues(
                                alpha: 0.02 + 0.04 * _animation.value,
                              ),
                            ],
                            stops: const [0.0, 0.3, 0.7, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 4. Iridescent & Refractive Outline Border Paint
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _IridescentBorderPainter(
                          borderRadius: widget.borderRadius,
                          hoverProgress: _animation.value,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _IridescentBorderPainter extends CustomPainter {
  final double borderRadius;
  final double hoverProgress;

  _IridescentBorderPainter({
    required this.borderRadius,
    required this.hoverProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    final paint = Paint()
      ..strokeWidth = 1.0 + 0.5 * hoverProgress
      ..style = PaintingStyle.stroke
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.5 + 0.3 * hoverProgress),
          AppColors.primary.withValues(alpha: 0.2 + 0.4 * hoverProgress),
          AppColors.secondary.withValues(alpha: 0.15 + 0.35 * hoverProgress),
          AppColors.tertiary.withValues(alpha: 0.1 + 0.3 * hoverProgress),
          Colors.white.withValues(alpha: 0.3 + 0.2 * hoverProgress),
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _IridescentBorderPainter oldDelegate) {
    return oldDelegate.hoverProgress != hoverProgress ||
        oldDelegate.borderRadius != borderRadius;
  }
}
