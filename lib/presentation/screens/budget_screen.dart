import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/category.dart';
import '../providers/app_providers.dart';
import '../widgets/glass_card.dart';
import '../widgets/shimmer_progress_bar.dart';

// Cached number formatter for currency values
final NumberFormat _currencyFormatter = NumberFormat('#,##,###', 'en_IN');

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryBudgets = ref.watch(categoryBudgetsProvider);
    final spending = ref.watch(spendingByCategoryProvider);
    final totalSpent = ref.watch(totalSpentProvider);
    final totalBudget = ref.watch(totalBudgetProvider);
    final currency = ref.watch(currencySymbolProvider);
    final formatter = _currencyFormatter; // use cached formatter

    final sumOfCategoryBudgets = categoryBudgets.values.fold(0.0, (sum, val) => sum + val);

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        dragStartBehavior: DragStartBehavior.down,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              'Budget',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('MMMM yyyy').format(DateTime.now()),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
            ),

            const SizedBox(height: 24),

            // Overall Budget Summary
            GlassCard(
              showGlow: true,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Budget',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: AppColors.outline,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$currency${formatter.format(totalBudget)}',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '(Sum of categories: $currency${formatter.format(sumOfCategoryBudgets)})',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.outline,
                                ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Spent',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: AppColors.outline,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$currency${formatter.format(totalSpent)}',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: totalSpent > totalBudget
                                      ? AppColors.debit
                                      : AppColors.primary,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ShimmerProgressBar(
                    progress: totalBudget > 0 ? totalSpent / totalBudget : 0,
                    height: 12,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0).clamp(0, 999).toStringAsFixed(0)}% used',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.outline,
                            ),
                      ),
                      Text(
                        '$currency${formatter.format((totalBudget - totalSpent).clamp(0, double.infinity))} remaining',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.primary,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            Text(
              'Category Budgets',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // Category Budget Cards
            for (final category in [
              TransactionCategory.food,
              TransactionCategory.travel,
              TransactionCategory.shopping,
              TransactionCategory.bills,
              TransactionCategory.entertainment,
              TransactionCategory.health,
              TransactionCategory.other,
            ]) ...[
              _buildCategoryBudgetCard(
                context,
                ref,
                category.index,
                categoryBudgets[category.index] ?? 0.0,
                spending[category.index] ?? 0.0,
                formatter,
              ),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBudgetCard(
    BuildContext context,
    WidgetRef ref,
    int categoryIndex,
    double limit,
    double spent,
    NumberFormat formatter,
  ) {
    final currency = ref.watch(currencySymbolProvider);
    final category = TransactionCategory.values[categoryIndex];
    final progress = limit > 0 ? spent / limit : 0.0;
    final isOverBudget = limit > 0 && spent > limit;

    return GestureDetector(
      onTap: () => _showEditBudgetDialog(context, ref, categoryIndex, limit),
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: category.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    category.icon,
                    color: category.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.label,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        limit > 0
                            ? '$currency${formatter.format(spent)} / $currency${formatter.format(limit)}'
                            : '$currency${formatter.format(spent)} / Not set',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.outline,
                            ),
                      ),
                    ],
                  ),
                ),
                // Edit budget button
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 16,
                    color: AppColors.outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ShimmerProgressBar(
              progress: progress,
              color: category.color,
            ),
            if (isOverBudget) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 14, color: AppColors.debit),
                  const SizedBox(width: 4),
                  Text(
                    'Over budget by $currency${formatter.format(spent - limit)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.debit,
                        ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showEditBudgetDialog(
      BuildContext context, WidgetRef ref, int categoryIndex, double currentLimit) {
    final currency = ref.read(currencySymbolProvider);
    final controller = TextEditingController(text: currentLimit > 0 ? currentLimit.toStringAsFixed(0) : '');
    final category = TransactionCategory.values[categoryIndex];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Icon(category.icon, color: category.color, size: 22),
              const SizedBox(width: 10),
              Text(
                'Edit ${category.label} Budget',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                decoration: InputDecoration(
                  prefixText: '$currency ',
                  prefixStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                  hintText: 'Monthly limit',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.outline,
                    ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final newLimit = double.tryParse(controller.text) ?? 0.0;
                if (newLimit >= 0) {
                  ref.read(categoryBudgetsProvider.notifier).setState(
                        categoryIndex,
                        newLimit,
                      );
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
