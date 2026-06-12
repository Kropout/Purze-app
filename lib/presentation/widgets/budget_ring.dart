import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/theme/app_colors.dart';

class BudgetRing extends StatefulWidget {
  final double spent;
  final double total;
  final double size;

  const BudgetRing({
    super.key,
    required this.spent,
    required this.total,
    this.size = 180,
  });

  @override
  State<BudgetRing> createState() => _BudgetRingState();
}

class _BudgetRingState extends State<BudgetRing>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500), // Slower linear animation
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    );
    
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 400), // Glow radiates 2x faster
      vsync: this,
    )..repeat();

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasBudget = widget.total > 0;
    final targetPercentage = !hasBudget
        ? 0.0
        : (widget.spent / widget.total).clamp(0.0, 1.0);
    final isOverBudget = hasBudget && widget.spent > widget.total;

    final valueColor = !hasBudget
        ? AppColors.outline
        : (isOverBudget ? AppColors.debit : AppColors.primary);



    return AnimatedBuilder(
      animation: Listenable.merge([_animation, _glowController]),
      builder: (context, child) {
      double currentPercentage = targetPercentage * _animation.value;

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _BudgetRingPainter(
              progress: currentPercentage,
              isOverBudget: isOverBudget,
              hasBudget: hasBudget,
              glowProgress: _glowController.value,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(currentPercentage * 100).toInt()}%',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: valueColor,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'of budget used',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.outline,
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BudgetRingPainter extends CustomPainter {
  final double progress;
  final bool isOverBudget;
  final bool hasBudget;
  final double glowProgress;

  _BudgetRingPainter({
    required this.progress,
    required this.isOverBudget,
    required this.hasBudget,
    required this.glowProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 24) / 2;
    const strokeWidth = 12.0;

    // Background track
    final bgPaint = Paint()
      ..color = AppColors.surfaceContainerHigh
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: !hasBudget
            ? [
                AppColors.outlineVariant.withValues(alpha: 0.25),
                AppColors.outlineVariant.withValues(alpha: 0.6),
              ]
            : isOverBudget
                ? [
                    AppColors.debit.withValues(alpha: 0.6),
                    AppColors.debit,
                  ]
                : [
                    AppColors.primary.withValues(alpha: 0.4),
                    AppColors.primary,
                  ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );

    // Glow dot at the end
    if (progress > 0.01) {
      final casinoValues = const [0, 15, 33, 48, 52, 69, 81, 95, 100];
      final angle = -math.pi / 2 + 2 * math.pi * progress;
      final dotX = center.dx + radius * math.cos(angle);
      final dotY = center.dy + radius * math.sin(angle);

      // Radiating glow effect - radiates outward 2x faster (400ms duration)
      final glowPaint = Paint()
        ..color = (isOverBudget ? AppColors.debit : AppColors.primary)
            .withValues(alpha: 0.5 * (1.0 - glowProgress))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, (6 + 14 * glowProgress) * 0.5);
      canvas.drawCircle(Offset(dotX, dotY), 6 + 14 * glowProgress, glowPaint);

      final dotPaint = Paint()
        ..color = isOverBudget ? AppColors.debit : AppColors.primary;
      canvas.drawCircle(Offset(dotX, dotY), 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BudgetRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isOverBudget != isOverBudget ||
        oldDelegate.hasBudget != hasBudget ||
        oldDelegate.glowProgress != glowProgress;
  }
}
