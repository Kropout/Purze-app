import 'package:flutter/material.dart';
import 'dart:ui';

import '../../domain/entities/category.dart';
import 'bubble_hover.dart';

class CategoryChip extends StatelessWidget {
  final TransactionCategory? category;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showAll;

  const CategoryChip({
    super.key,
    this.category,
    required this.isSelected,
    required this.onTap,
    this.showAll = false,
  });
  @override
  Widget build(BuildContext context) {
    final label = showAll ? 'All' : category!.label;
    final theme = Theme.of(context);
    final color = showAll ? theme.colorScheme.primary : category!.color;

    return BubbleHover(
      borderRadius: 24,
      onTap: onTap,
      enableGlow: isSelected,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.25)
                  : theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.45,
                    ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected
                    ? color.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.05),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!showAll) ...[
                  Icon(category!.icon, size: 16, color: color),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isSelected
                        ? color
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
