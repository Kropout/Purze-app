import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    final initialPage = ref.read(selectedTabProvider);
    _pageController = PageController(initialPage: initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedTab = ref.watch(selectedTabProvider);

    // Sync PageView when Riverpod state changes from bottom navigation taps
    ref.listen<int>(selectedTabProvider, (previous, next) {
      if (_pageController.hasClients && _pageController.page?.round() != next) {
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });

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
        extendBody:
            true, // Allows page content to scroll behind the floating glass capsule
        body: PageView.builder(
          controller: _pageController,
          itemCount: screens.length,
          itemBuilder: (context, index) => screens[index],
          onPageChanged: (index) {
            ref.read(selectedTabProvider.notifier).state = index;
            HapticFeedback.lightImpact();
          },
          physics: const BouncingScrollPhysics(
            decelerationRate: ScrollDecelerationRate.normal,
          ),
        ),
        bottomNavigationBar: Container(
          margin: EdgeInsets.zero,
          child: BubbleHover(
            customBorderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            enableScale:
                false, // Capsule container does not scale, items inside scale instead
            enableGlow: true,
            child: Container(
              height: 72 + MediaQuery.paddingOf(context).bottom,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                // Semi-translucent base background
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainer.withValues(alpha: 0.45),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 5,
                    sigmaY: 5,
                  ), // Reduced blur by 25%
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      4,
                      0,
                      4,
                      MediaQuery.paddingOf(context).bottom,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(
                          context,
                          ref,
                          0,
                          Icons.home_outlined,
                          Icons.home_rounded,
                          'Home',
                          selectedTab,
                        ),
                        _buildNavItem(
                          context,
                          ref,
                          1,
                          Icons.receipt_long_outlined,
                          Icons.receipt_long_rounded,
                          'Txns',
                          selectedTab,
                        ),
                        _buildNavItem(
                          context,
                          ref,
                          2,
                          Icons.pie_chart_outline_rounded,
                          Icons.pie_chart_rounded,
                          'Analytics',
                          selectedTab,
                        ),
                        _buildNavItem(
                          context,
                          ref,
                          3,
                          Icons.account_balance_wallet_outlined,
                          Icons.account_balance_wallet_rounded,
                          'Budget',
                          selectedTab,
                        ),
                        _buildNavItem(
                          context,
                          ref,
                          4,
                          Icons.settings_outlined,
                          Icons.settings_rounded,
                          'Settings',
                          selectedTab,
                        ),
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
    final color = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.outline;

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
                Icon(isSelected ? selectedIcon : icon, color: color, size: 24),
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
