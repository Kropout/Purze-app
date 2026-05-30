import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/category.dart';
import '../providers/app_providers.dart';
import '../widgets/glass_card.dart';
import '../widgets/budget_ring.dart';
import '../widgets/category_chip.dart';
import '../widgets/transaction_tile.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(allTransactionsProvider);
    final totalSpent = ref.watch(totalSpentProvider);
    final totalBudget = ref.watch(totalBudgetProvider);
    final currency = ref.watch(currencySymbolProvider);
    final rawName = ref.watch(userNameProvider).trim();
    final displayName = rawName.isEmpty ? 'Hey there' : rawName;
    final recentTransactions = transactions.take(5).toList();
    final formatter = NumberFormat('#,##,###', 'en_IN');

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            // ─── Greeting ───
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayName,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ─── Budget Ring Card ───
            GlassCard(
              showGlow: true,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Monthly Budget',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          DateFormat('MMMM yyyy').format(DateTime.now()),
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  BudgetRing(
                    spent: totalSpent,
                    total: totalBudget,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStat(
                        context,
                        'Spent',
                        '$currency${formatter.format(totalSpent)}',
                        AppColors.debit,
                      ),
                      Container(
                        width: 1,
                        height: 36,
                        color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.25),
                      ),
                      _buildStat(
                        context,
                        'Remaining',
                        '$currency${formatter.format((totalBudget - totalSpent).clamp(0, double.infinity))}',
                        AppColors.credit,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ─── Category Chips ───
            Text(
              'Categories',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final cat in [
                    TransactionCategory.food,
                    TransactionCategory.travel,
                    TransactionCategory.shopping,
                    TransactionCategory.bills,
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: CategoryChip(
                        category: cat,
                        isSelected: false,
                        onTap: () {
                          ref.read(selectedCategoryFilterProvider.notifier).state = cat;
                          ref.read(selectedTabProvider.notifier).state = 1;
                        },
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ─── Recent Transactions ───
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                GestureDetector(
                  onTap: () {
                    ref.read(selectedTabProvider.notifier).state = 1;
                  },
                  child: Text(
                    'See All',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  if (recentTransactions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No transactions yet. Your UPI transactions will appear here automatically.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    )
                  else
                    for (int i = 0; i < recentTransactions.length; i++) ...[
                      TransactionTile(transaction: recentTransactions[i]),
                      if (i < recentTransactions.length - 1)
                        const SizedBox(height: 4),
                    ],
                ],
              ),
            ),

            const SizedBox(height: 100), // bottom nav space
          ],
        ),
      ),
    );
  }

  Widget _buildStat(
      BuildContext context, String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: valueColor,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }
}
