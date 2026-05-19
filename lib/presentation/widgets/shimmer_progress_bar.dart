import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ShimmerProgressBar extends StatefulWidget {
  final double progress;
  final Color? color;
  final double height;

  const ShimmerProgressBar({
    super.key,
    required this.progress,
    this.color,
    this.height = 10,
  });

  @override
  State<ShimmerProgressBar> createState() => _ShimmerProgressBarState();
}

class _ShimmerProgressBarState extends State<ShimmerProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.primary;
    final isOverBudget = widget.progress > 1.0;
    final barColor = isOverBudget ? AppColors.debit : color;
    final clampedProgress = widget.progress.clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth * clampedProgress;
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(widget.height),
          ),
          child: Stack(
            children: [
              // Fill
              AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOutCubic,
                width: barWidth,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      barColor.withValues(alpha: 0.7),
                      barColor,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(widget.height),
                ),
              ),
              // Shimmer
              if (clampedProgress > 0.05)
                AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, child) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(widget.height),
                      child: SizedBox(
                        width: barWidth,
                        child: ShaderMask(
                          shaderCallback: (bounds) {
                            return LinearGradient(
                              begin: Alignment(-1.0 + 3.0 * _shimmerController.value, 0),
                              end: Alignment(-0.5 + 3.0 * _shimmerController.value, 0),
                              colors: const [
                                Colors.transparent,
                                AppColors.shimmer,
                                Colors.transparent,
                              ],
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.srcATop,
                          child: Container(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
