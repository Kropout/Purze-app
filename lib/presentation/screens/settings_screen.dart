import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../providers/app_providers.dart';
import '../widgets/glass_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Customize your experience',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.outline,
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
                    icon: Icons.dark_mode_rounded,
                    iconColor: AppColors.primary,
                    title: 'Dark Mode',
                    subtitle: 'Currently active',
                    trailing: Switch(
                      value: true,
                      onChanged: (value) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Only dark theme available in this version'),
                            backgroundColor: AppColors.surfaceContainerHighest,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                      activeColor: AppColors.primary,
                      activeTrackColor: AppColors.primaryContainer,
                      inactiveThumbColor: AppColors.outline,
                      inactiveTrackColor: AppColors.surfaceContainerHigh,
                    ),
                  ),
                  _buildDivider(),
                  _buildSettingTile(
                    context,
                    icon: Icons.currency_rupee_rounded,
                    iconColor: AppColors.secondary,
                    title: 'Currency',
                    subtitle: 'Indian Rupee (₹)',
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: AppColors.outline),
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
                    iconColor: AppColors.primary,
                    title: 'Export Data',
                    subtitle: 'Save transactions as CSV',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Export coming in next update!'),
                          backgroundColor: AppColors.surfaceContainerHighest,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: AppColors.outline),
                  ),
                  _buildDivider(),
                  _buildSettingTile(
                    context,
                    icon: Icons.delete_outline_rounded,
                    iconColor: AppColors.debit,
                    title: 'Clear All Data',
                    subtitle: 'Delete all transactions and budgets',
                    onTap: () {
                      _showClearDataDialog(context, ref);
                    },
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: AppColors.outline),
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
                    iconColor: AppColors.primary,
                    title: 'App Version',
                    subtitle: 'v1.0.0',
                    trailing: const SizedBox.shrink(),
                  ),
                  _buildDivider(),
                  _buildSettingTile(
                    context,
                    icon: Icons.shield_outlined,
                    iconColor: AppColors.secondary,
                    title: 'Privacy',
                    subtitle: 'All data stays on your device',
                    trailing: const Icon(Icons.verified_rounded,
                        color: AppColors.credit, size: 20),
                  ),
                  _buildDivider(),
                  _buildSettingTile(
                    context,
                    icon: Icons.code_rounded,
                    iconColor: AppColors.tertiary,
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your finances, your device, your control.',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.outline,
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
            color: AppColors.outline,
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
                          color: AppColors.outline,
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

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 18),
      child: Divider(
        height: 1,
        color: Color(0x0F3F4945), // ghost border (outlineVariant at 6%)
      ),
    );
  }

  void _showClearDataDialog(BuildContext context, WidgetRef ref) {
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
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.debit, size: 24),
              const SizedBox(width: 10),
              Text(
                'Clear All Data?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          content: Text(
            'This will permanently delete all your transactions and budget data. This action cannot be undone.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.debit,
              ),
              onPressed: () async {
                final repo = ref.read(transactionRepositoryProvider);
                await repo.clearAllData();
                ref.read(allTransactionsProvider.notifier).refresh();
                ref.read(allBudgetsProvider.notifier).refresh();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('All data cleared'),
                      backgroundColor: AppColors.surfaceContainerHighest,
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
