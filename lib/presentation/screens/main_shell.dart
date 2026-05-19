import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../../core/theme/app_colors.dart';
import '../providers/app_providers.dart';
import '../widgets/bubble_hover.dart';
import 'home_screen.dart';
import 'transactions_screen.dart';
import 'analytics_screen.dart';
import 'budget_screen.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(selectedTabProvider);

    final screens = const [
      HomeScreen(),
      TransactionsScreen(),
      AnalyticsScreen(),
      BudgetScreen(),
    ];

    return Scaffold(
      extendBody: true, // Allows page content to scroll behind the floating glass capsule
      body: IndexedStack(
        index: selectedTab,
        children: screens,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 16), // Premium Floating Pill position
          child: BubbleHover(
            borderRadius: 24,
            enableScale: false, // Capsule container does not scale, items inside scale instead
            enableGlow: true,
            child: Container(
              height: 74,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                // Semi-translucent base background
                color: AppColors.surfaceContainer.withValues(alpha: 0.4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(ref, 0, Icons.home_outlined, Icons.home_rounded, 'Home', selectedTab),
                        _buildNavItem(ref, 1, Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Transactions', selectedTab),
                        _buildNavItem(ref, 2, Icons.pie_chart_outline_rounded, Icons.pie_chart_rounded, 'Analytics', selectedTab),
                        _buildNavItem(ref, 3, Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded, 'Budget', selectedTab),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    WidgetRef ref,
    int index,
    IconData icon,
    IconData selectedIcon,
    String label,
    int selectedTab,
  ) {
    final isSelected = selectedTab == index;
    final color = isSelected ? AppColors.primary : AppColors.outline;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: BubbleHover(
          borderRadius: 16,
          enableGlow: false,
          onTap: () {
            ref.read(selectedTabProvider.notifier).state = index;
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.transparent,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    // Micro glass selection bubble
                    color: isSelected
                        ? AppColors.primaryContainer.withValues(alpha: 0.25)
                        : Colors.transparent,
                  ),
                  child: Icon(
                    isSelected ? selectedIcon : icon,
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
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
