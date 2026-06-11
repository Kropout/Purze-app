import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/transaction_model.dart';
import '../../domain/entities/category.dart';
import '../providers/app_providers.dart';
import 'bubble_hover.dart';

class TransactionTile extends ConsumerWidget {
  final TransactionModel transaction;

  const TransactionTile({super.key, required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencySymbolProvider);
    final category = transaction.category;
    final isDebit = transaction.isDebit;
    final amountColor = isDebit ? AppColors.debit : AppColors.credit;
    final amountPrefix = isDebit ? '- ' : '+ ';
    final formatter = NumberFormat('#,##,###', 'en_IN');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: BubbleHover(
        borderRadius: 14,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                // Very subtle glass layer
                color: AppColors.surfaceContainerHighest.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  // Category icon container - Styled as a micro glass bubble
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: category.color.withValues(alpha: 0.25),
                        width: 0.5,
                      ),
                    ),
                    child: _getCategoryIcon(category),
                  ),
                  const SizedBox(width: 14),
                  // Merchant & date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.merchant,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _formatDate(transaction.date),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.outline,
                              ),
                        ),
                      ],
                    ),
                  ),
                  // Amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$amountPrefix$currency${formatter.format(transaction.amount)}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: amountColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        category.label,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: category.color.withValues(alpha: 0.7),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _getCategoryIcon(TransactionCategory category) {
    if (category.icon == Icons.help_outline_rounded) {
      // Default profile-like avatar
      return Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.circle, color: category.color.withValues(alpha: 0.5), size: 36),
          Icon(Icons.circle, color: category.color.withValues(alpha: 0.7), size: 24),
          Icon(Icons.person, color: Colors.white, size: 16),
        ],
      );
    }
    return Icon(
      category.icon,
      color: category.color,
      size: 20,
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);

    if (dateDay == today) {
      return 'Today, ${DateFormat('h:mm a').format(date)}';
    } else if (dateDay == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, ${DateFormat('h:mm a').format(date)}';
    } else {
      return DateFormat('d MMM, h:mm a').format(date);
    }
  }
}

