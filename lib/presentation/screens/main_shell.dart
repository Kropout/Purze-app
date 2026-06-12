import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';

import '../providers/app_providers.dart';
import '../widgets/ambient_background.dart';
import '../widgets/bubble_hover.dart';
import 'home_screen.dart';
import 'transactions_screen.dart';
import 'analytics_screen.dart';
import 'budget_screen.dart';
import 'settings_screen.dart';

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
      SettingsScreen(),
    ];

    return AmbientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true, // Allows page content to scroll behind the floating glass capsule
        body: IndexedStack(
          index: selectedTab,
          children: screens,
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(0, 0, 0, 16), // Premium Floating Pill position edge-to-edge, 16px above bottom
            child: BubbleHover(
              borderRadius: 24,
              enableScale: false, // Capsule container does not scale, items inside scale instead
              enableGlow: true,
              child: Container(
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  // Semi-translucent base background
                  color: Theme.of(context).colorScheme.surfaceContainer.withValues(alpha: 0.45),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNavItem(context, ref, 0, Icons.home_outlined, Icons.home_rounded, 'Home', selectedTab),
                          _buildNavItem(context, ref, 1, Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Txns', selectedTab),
                          _buildNavItem(context, ref, 2, Icons.pie_chart_outline_rounded, Icons.pie_chart_rounded, 'Analytics', selectedTab),
                          _buildNavItem(context, ref, 3, Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded, 'Budget', selectedTab),
                          _buildNavItem(context, ref, 4, Icons.settings_outlined, Icons.settings_rounded, 'Settings', selectedTab),
                        ],
                      ),
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
    BuildContext context,
    WidgetRef ref,
    int index,
    IconData icon,
    IconData selectedIcon,
    String label,
    int selectedTab,
  ) {
    final isSelected = selectedTab == index;
    final theme = Theme.of(context);
    final color = isSelected ? theme.colorScheme.primary : theme.colorScheme.outline;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(selectedTabProvider.notifier).state = index;
        },
        behavior: HitTestBehavior.opaque,
        child: Padding(
          // 10px top+bottom inset from the 72px nav bar = 52px tall capsule
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              // Full circular radius = true capsule, no sharp edges
              borderRadius: BorderRadius.circular(9999),
              color: isSelected
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.30)
                  : Colors.transparent,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  color: color,
                  size: 24,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
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
