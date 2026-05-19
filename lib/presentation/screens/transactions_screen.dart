import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/category.dart';
import '../providers/app_providers.dart';
import '../widgets/category_chip.dart';
import '../widgets/transaction_tile.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(searchedTransactionsProvider);
    final selectedCategory = ref.watch(selectedCategoryFilterProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Transactions',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: 20),
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).state = value;
              },
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Search merchants, amounts...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.outline,
                ),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: AppColors.outline),
                        onPressed: () {
                          ref.read(searchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Category Filters
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CategoryChip(
                    showAll: true,
                    isSelected: selectedCategory == null,
                    onTap: () {
                      ref.read(selectedCategoryFilterProvider.notifier).state =
                          null;
                    },
                  ),
                ),
                for (final cat in TransactionCategory.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CategoryChip(
                      category: cat,
                      isSelected: selectedCategory == cat,
                      onTap: () {
                        ref
                            .read(selectedCategoryFilterProvider.notifier)
                            .state = selectedCategory == cat ? null : cat;
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Transaction Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '${transactions.length} transactions',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.outline,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          // Transaction List
          Expanded(
            child: transactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 48,
                          color: AppColors.outline.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No transactions found',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.outline,
                                  ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      // Group by date header
                      final transaction = transactions[index];
                      final showDateHeader = index == 0 ||
                          _differentDay(
                              transactions[index - 1].date, transaction.date);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showDateHeader) ...[
                            const SizedBox(height: 12),
                            Text(
                              _formatDateHeader(transaction.date),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: AppColors.outline,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          TransactionTile(transaction: transaction),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  bool _differentDay(DateTime a, DateTime b) {
    return a.year != b.year || a.month != b.month || a.day != b.day;
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);

    if (dateDay == today) return 'Today';
    if (dateDay == today.subtract(const Duration(days: 1))) return 'Yesterday';
    final diff = today.difference(dateDay).inDays;
    if (diff < 7) return '$diff days ago';
    return '${date.day} ${_monthName(date.month)}';
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}
