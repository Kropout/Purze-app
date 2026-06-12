import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
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
    final formatter = NumberFormat.decimalPattern('en_IN');
    final estimated = ref.watch(estimatedBalanceProvider);
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        dragStartBehavior: DragStartBehavior.down,
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
                  _getGreetingLabel(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getCozyGreeting(displayName),
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
                      AnimatedBudgetStat(
                        label: 'Spent',
                        targetValue: totalSpent,
                        valueColor: AppColors.debit,
                        currency: currency,
                        formatter: formatter,
                      ),
                      Container(
                        width: 1,
                        height: 36,
                        color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.25),
                      ),
                      AnimatedBudgetStat(
                        label: 'Remaining',
                        targetValue: (totalBudget - totalSpent).clamp(0, double.infinity),
                        valueColor: AppColors.credit,
                        currency: currency,
                        formatter: formatter,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ─── Estimated Balance Card ───
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estimated Balance',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      const cap = 10000000; // ₹1 crore
                      final tooHigh = estimated.abs() > cap;
                      if (tooHigh) {
                        return Text(
                          'Balance seems incorrect',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).colorScheme.error,
                              ),
                        );
                      }

                      return Text(
                        '$currency${formatter.format(estimated)}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  Text(
                    (estimated.abs() > 10000000)
                        ? 'We detected an unusually large balance. Please re-import SMS after updating filters.'
                        : 'Based on UPI transactions only',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
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
                dragStartBehavior: DragStartBehavior.down,
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



  String _getGreetingLabel() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 6) return 'EARLY BIRD';
    if (hour >= 6 && hour < 12) return 'WELCOME BACK';
    if (hour >= 12 && hour < 17) return 'MIDDAY REVIEW';
    if (hour >= 17 && hour < 21) return 'UNWIND';
    return 'REST & RECHARGE';
  }

  String _getCozyGreeting(String name) {
    final hour = DateTime.now().hour;
    final seed = DateTime.now().day + DateTime.now().hour;
    
    final List<String> messages;
    if (hour >= 4 && hour < 6) {
      messages = [
        "Rise and shine, $name",
        "Up with the birds, $name?",
        "A fresh start awaits, $name",
        "Early start today, $name?",
        "The world is quiet, $name",
        "Ready to conquer, $name?",
        "Quiet mornings are the best, $name",
        "Dawn of a new day, $name",
        "Let's make today count, $name",
        "Chase your dreams, $name",
      ];
    } else if (hour >= 6 && hour < 12) {
      messages = [
        "Good morning, $name",
        "Have a wonderful morning, $name",
        "Hope you slept well, $name",
        "Ready for a great day, $name?",
        "Wishing you a bright morning, $name",
        "Grab your coffee, $name",
        "Let's do this, $name!",
        "A beautiful morning, $name",
        "Hope your day starts well, $name",
        "Make today amazing, $name",
      ];
    } else if (hour >= 12 && hour < 17) {
      messages = [
        "Good afternoon, $name",
        "How is your day going, $name?",
        "Midday check-in, $name",
        "Taking a quick break, $name?",
        "Hope your afternoon is productive, $name",
        "Keep pushing forward, $name",
        "Halfway through the day, $name",
        "Stay focused, $name",
        "Time for a stretch, $name?",
        "Wishing you a calm afternoon, $name",
      ];
    } else if (hour >= 17 && hour < 21) {
      messages = [
        "Good evening, $name",
        "Time to unwind, $name",
        "Hope you had a good day, $name",
        "Evening reflection, $name",
        "Relax and recharge, $name",
        "Sun is setting, time to rest, $name",
        "Cozy evening vibes, $name",
        "How did the day go, $name?",
        "Peaceful evening to you, $name",
        "Time to log off soon, $name",
      ];
    } else {
      messages = [
        "Rest well, $name",
        "Sweet dreams, $name",
        "Late night check-in, $name",
        "Quiet night, $name",
        "Time to sleep soon, $name",
        "Unwinding for the night, $name",
        "Sleep tight, $name",
        "Hope you had a restful day, $name",
        "Peaceful night, $name",
        "Off to bed, $name?",
      ];
    }

    final index = seed % messages.length;
    return messages[index];
  }
}

class AnimatedBudgetStat extends StatefulWidget {
  final String label;
  final double targetValue;
  final Color valueColor;
  final String currency;
  final NumberFormat formatter;

  const AnimatedBudgetStat({
    super.key,
    required this.label,
    required this.targetValue,
    required this.valueColor,
    required this.currency,
    required this.formatter,
  });

  @override
  State<AnimatedBudgetStat> createState() => _AnimatedBudgetStatState();
}

class _AnimatedBudgetStatState extends State<AnimatedBudgetStat>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000), // Animate for 3.0s (2.8-3.1s range)
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final casinoValues = const [0, 5, 8, 15, 78, 31, 12, 56, 60];

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        double currentValue;
        if (_animation.value < 0.85) {
          final index = ((_animation.value / 0.85) * (casinoValues.length - 1)).toInt();
          final pct = casinoValues[index.clamp(0, casinoValues.length - 1)] / 100.0;
          currentValue = widget.targetValue * pct;
        } else {
          currentValue = widget.targetValue;
        }

        return Column(
          children: [
            Text(
              widget.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.currency}${widget.formatter.format(currentValue)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: widget.valueColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        );
      },
    );
  }
}
