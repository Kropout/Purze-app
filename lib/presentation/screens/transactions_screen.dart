import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/category.dart';
import '../../data/models/transaction_model.dart';
import '../providers/app_providers.dart';
import '../widgets/category_chip.dart';
import '../widgets/transaction_tile.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  late final ScrollController _scrollController;
  int _visibleCount = 20;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    const threshold = 200.0;
    if (maxScroll - currentScroll <= threshold) {
      final total = ref.read(searchedTransactionsProvider).length;
      if (_visibleCount < total) {
        setState(() {
          _visibleCount = (_visibleCount + 20).clamp(0, total);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reset visible count when search results or filters change
    ref.listen<List<TransactionModel>>(searchedTransactionsProvider, (previous, next) {
      if (mounted) {
        setState(() {
          _visibleCount = 20;
        });
      }
    });

    final transactions = ref.watch(searchedTransactionsProvider);
    final selectedCategory = ref.watch(selectedCategoryFilterProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final displayCount = _visibleCount.clamp(0, transactions.length);

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
              dragStartBehavior: DragStartBehavior.down,
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
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    dragStartBehavior: DragStartBehavior.down,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: displayCount,
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

