import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../providers/app_providers.dart';
import '../widgets/glass_card.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _budgetController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _budgetController = TextEditingController();
    _loadUserData();
  }

  void _loadUserData() {
    try {
      final box = Hive.box(AppConstants.settingsBox);
      _nameController.text = (box.get(AppConstants.userNameKey) as String?) ?? '';
      
      final mb = box.get(AppConstants.monthlyBudgetKey, defaultValue: 0);
      final mbDouble = mb is int ? mb.toDouble() : (mb is double ? mb : 0.0);
      _budgetController.text = mbDouble <= 0 ? '' : mbDouble.toStringAsFixed(0);
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    try {
      final box = Hive.box(AppConstants.settingsBox);
      await box.put(AppConstants.userNameKey, name);
      final _ = ref.refresh(userNameProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Name updated'),
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(milliseconds: 1500),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _saveBudget() async {
    final raw = _budgetController.text.replaceAll(',', '').trim();
    final value = double.tryParse(raw) ?? 0;
    await ref.read(monthlyBudgetProvider.notifier).setBudget(value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Budget updated'),
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(milliseconds: 1500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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

            // ─── Profile Section ───
            _buildSectionHeader(context, 'Profile'),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Your Name',
                      hintText: 'Enter your name',
                      prefixIcon: Icon(
                        Icons.person_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveName,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Save Name',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ─── Budget Section ───
            _buildSectionHeader(context, 'Budget'),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _budgetController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: false,
                      signed: false,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Monthly Budget',
                      hintText: 'Enter monthly budget',
                      prefixIcon: Icon(
                        Icons.currency_rupee_rounded,
                        color: theme.colorScheme.secondary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.secondary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveBudget,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Save Budget',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

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
                      _showClearDataDialog(context);
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
                    title: 'Privacy Policy',
                    subtitle: 'Read our privacy policy',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrivacyPolicyScreen(),
                        ),
                      );
                    },
                    trailing: Icon(Icons.chevron_right_rounded,
                        color: theme.colorScheme.outline),
                  ),
                  _buildDivider(context),
                  _buildSettingTile(
                    context,
                    icon: Icons.description_outlined,
                    iconColor: theme.colorScheme.tertiary,
                    title: 'Terms & Conditions',
                    subtitle: 'Read our terms & conditions',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TermsConditionsScreen(),
                        ),
                      );
                    },
                    trailing: Icon(Icons.chevron_right_rounded,
                        color: theme.colorScheme.outline),
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

  void _showClearDataDialog(BuildContext context) {
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
            'Are you sure? This will delete all transactions and reset the app.',
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
                
                final settingsBox = Hive.box(AppConstants.settingsBox);
                await settingsBox.clear();
                
                await ref.read(hasOnboardedProvider.notifier).reset();
                
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  Navigator.of(ctx, rootNavigator: true).popUntil((route) => route.isFirst);
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

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Privacy Policy',
          style: theme.textTheme.headlineSmall,
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Privacy Matters',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Purze is designed with your privacy as a top priority. All your financial data stays on your device. We do not collect, store, or transmit any of your personal information or transaction data to external servers.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Data Storage',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'All transactions, budgets, and settings are stored locally on your device using Hive database. No data is ever sent to our servers.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Data Usage',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your data is used solely for the purpose of helping you manage your finances. We do not share, sell, or analyze your personal data.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Permissions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Purze may request permissions for specific features, but these are optional and only used for the features you choose to enable.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Terms & Conditions',
          style: theme.textTheme.headlineSmall,
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Terms & Conditions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'By using Purze, you agree to these terms and conditions. Please read them carefully.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Use License',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We grant you a limited, non-exclusive, and non-transferable license to use Purze for personal financial management purposes only.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Disclaimer',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Purze is provided "as is" without warranties of any kind. We do not guarantee accuracy, reliability, or completeness of the app. You use the app at your own risk.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Limitation of Liability',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'In no event shall Purze be liable for any damages arising from your use of the app, including but not limited to financial losses.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Changes to Terms',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We may update these terms at any time. Continued use of the app constitutes acceptance of any changes.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
