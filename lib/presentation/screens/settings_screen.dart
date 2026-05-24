import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../providers/app_providers.dart';
import '../widgets/glass_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              'Settings',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Customize your experience',
              style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 32),

            // ─── Appearance Section ───
            _buildSectionHeader(context, 'Appearance'),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(0),
              child: Column(
                children: [
                  _buildSettingTile(
                    context,
                    icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    iconColor: isDark ? theme.colorScheme.primary : theme.colorScheme.secondary,
                    title: isDark ? 'Dark Mode' : 'Light Mode',
                    subtitle: isDark ? 'Sleek dark experience' : 'Soft premium theme',
                    trailing: Switch(
                      value: isDark,
                      onChanged: (value) {
                        ref.read(themeModeProvider.notifier).toggleTheme();
                      },
                      activeThumbColor: theme.colorScheme.primary,
                      activeTrackColor: theme.colorScheme.primaryContainer,
                      inactiveThumbColor: theme.colorScheme.outline,
                      inactiveTrackColor: theme.colorScheme.surfaceContainerHigh,
                    ),
                  ),
                  _buildDivider(context),
                  _buildSettingTile(
                    context,
                    icon: Icons.currency_rupee_rounded,
                    iconColor: theme.colorScheme.secondary,
                    title: 'Currency',
                    subtitle: 'Indian Rupee (₹)',
                    trailing: Icon(Icons.chevron_right_rounded,
                        color: theme.colorScheme.outline),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ─── Data Section ───
            _buildSectionHeader(context, 'Data Management'),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(0),
              child: Column(
                children: [
                  _buildSettingTile(
                    context,
                    icon: Icons.file_download_outlined,
                    iconColor: theme.colorScheme.primary,
                    title: 'Export Data',
                    subtitle: 'Save transactions as CSV',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Export coming in next update!'),
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                    trailing: Icon(Icons.chevron_right_rounded,
                        color: theme.colorScheme.outline),
                  ),
                  _buildDivider(context),
                  _buildSettingTile(
                    context,
                    icon: Icons.delete_outline_rounded,
                    iconColor: AppColors.debit,
                    title: 'Clear All Data',
                    subtitle: 'Delete all transactions and budgets',
                    onTap: () {
                      _showClearDataDialog(context, ref);
                    },
                    trailing: Icon(Icons.chevron_right_rounded,
                        color: theme.colorScheme.outline),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ─── About Section ───
            _buildSectionHeader(context, 'About'),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(0),
              child: Column(
                children: [
                  _buildSettingTile(
                    context,
                    icon: Icons.info_outline_rounded,
                    iconColor: theme.colorScheme.primary,
                    title: 'App Version',
                    subtitle: 'v1.0.0',
                    trailing: const SizedBox.shrink(),
                  ),
                  _buildDivider(context),
                  _buildSettingTile(
                    context,
                    icon: Icons.shield_outlined,
                    iconColor: theme.colorScheme.secondary,
                    title: 'Privacy',
                    subtitle: 'All data stays on your device',
                    trailing: Icon(Icons.verified_rounded,
                        color: theme.colorScheme.primary, size: 20),
                  ),
                  _buildDivider(context),
                  _buildSettingTile(
                    context,
                    icon: Icons.code_rounded,
                    iconColor: theme.colorScheme.tertiary,
                    title: 'Built With',
                    subtitle: 'Flutter + Riverpod + Hive',
                    trailing: const SizedBox.shrink(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Footer
            Center(
              child: Column(
                children: [
                  Text(
                    'Purze',
                    style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your finances, your device, your control.',
                    style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.outline,
            letterSpacing: 0.5,
          ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Divider(
        height: 1,
        color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
      ),
    );
  }

  void _showClearDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.debit, size: 24),
              const SizedBox(width: 10),
              Text(
                'Clear All Data?',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
          content: Text(
            'This will permanently delete all your transactions and budget data. This action cannot be undone.',
            style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.debit,
              ),
              onPressed: () async {
                final repo = ref.read(transactionRepositoryProvider);
                await repo.clearAllData();
                ref.read(allTransactionsProvider.notifier).refresh();
                ref.read(allBudgetsProvider.notifier).refresh();
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: const Text('All data cleared'),
                      backgroundColor: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }
}
