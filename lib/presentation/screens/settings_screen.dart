import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:local_auth/local_auth.dart';
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
  final _profileFormKey = GlobalKey<FormState>();
  final _budgetFormKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _budgetController;
  late final TextEditingController _startingBalanceController;

  int _accentColorValue = AppColors.primary.toARGB32();

  static const List<String> _currencyOptions = <String>['₹', r'$', '€', '£'];

  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: ref.read(userNameProvider));
    _phoneController = TextEditingController(text: ref.read(userPhoneProvider));
    _budgetController = TextEditingController();
    _startingBalanceController = TextEditingController();

    final mbDouble = ref.read(monthlyBudgetProvider);
    _budgetController.text = mbDouble <= 0 ? '' : mbDouble.toStringAsFixed(0);

    final sb = ref.read(startingBalanceProvider);
    _startingBalanceController.text = sb <= 0 ? '' : sb.toStringAsFixed(0);

    _accentColorValue = ref.read(accentColorValueProvider);

    // Check biometric support
    _checkBiometricSupport();
  }

  Future<void> _checkBiometricSupport() async {
    try {
      final auth = LocalAuthentication();
      final canCheck = await auth.canCheckBiometrics || await auth.isDeviceSupported();
      final enrolled = (await auth.getAvailableBiometrics()).isNotEmpty;
      if (mounted) setState(() => _biometricAvailable = canCheck && enrolled);
    } catch (_) {
      if (mounted) setState(() => _biometricAvailable = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _budgetController.dispose();
    _startingBalanceController.dispose();
    super.dispose();
  }

  String? _validateName(String? input) {
    final name = (input ?? '').trim();
    if (name.isEmpty) return 'Please enter your name';
    if (name.length > AppConstants.maxNameLength) {
      return 'Name can be max ${AppConstants.maxNameLength} characters';
    }
    final ok = RegExp(r'^[A-Za-z ]+$').hasMatch(name);
    if (!ok) return 'Only letters and spaces are allowed';
    return null;
  }

  String? _validatePhone(String? input) {
    final phone = (input ?? '').trim();
    if (phone.isEmpty) return null; // optional
    if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
      return 'Enter a valid 10-digit phone number';
    }
    return null;
  }

  String? _validateBudget(String? input) {
    final raw = (input ?? '').replaceAll(',', '').trim();
    if (raw.isEmpty) return null; // allow 0
    final value = double.tryParse(raw);
    if (value == null) return 'Enter a valid amount';
    if (value < 0) return 'Budget cannot be negative';
    if (value > AppConstants.maxMonthlyBudget) {
      return 'Budget cannot exceed ₹10,00,000';
    }
    return null;
  }

  Widget _accentPicker(BuildContext context) {
    final options = <Color>[
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).colorScheme.tertiary,
      AppColors.debit,
      AppColors.travelColor,
      AppColors.shoppingColor,
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final c in options)
          GestureDetector(
            onTap: () => setState(() => _accentColorValue = c.toARGB32()),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c,
                border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface.withValues(
                        alpha: _accentColorValue == c.toARGB32() ? 0.9 : 0.15,
                      ),
                  width: _accentColorValue == c.toARGB32() ? 2 : 1,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showCurrencyPicker(BuildContext context) {
    final current = ref.read(currencySymbolProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      Text('Select currency', style: theme.textTheme.titleMedium),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                for (final s in _currencyOptions)
                  ListTile(
                    title: Text('Currency: $s'),
                    trailing: current == s
                        ? Icon(Icons.check_rounded, color: theme.colorScheme.primary)
                        : null,
                    onTap: () async {
                      await ref.read(currencySymbolProvider.notifier).setSymbol(s);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    final ok = _profileFormKey.currentState?.validate() ?? false;
    if (!ok) return;

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    await ref.read(userNameProvider.notifier).setName(name);
    await ref.read(userPhoneProvider.notifier).setPhone(phone);
    await ref.read(accentColorValueProvider.notifier).setAccentColorValue(_accentColorValue);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated'),
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

  Future<void> _saveBudget() async {
    final ok = _budgetFormKey.currentState?.validate() ?? false;
    if (!ok) return;

    final raw = _budgetController.text.replaceAll(',', '').trim();
    final value = double.tryParse(raw) ?? 0;
    await ref.read(monthlyBudgetProvider.notifier).setBudget(value);

    // Also save starting balance if provided
    final rawSb = _startingBalanceController.text.replaceAll(',', '').trim();
    final sbValue = double.tryParse(rawSb) ?? 0;
    await ref.read(startingBalanceProvider.notifier).setStartingBalance(sbValue);

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
    final currency = ref.watch(currencySymbolProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
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
              child: Form(
                key: _profileFormKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      maxLength: AppConstants.maxNameLength,
                      textInputAction: TextInputAction.next,
                      validator: _validateName,
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
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      maxLength: 10,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: _validatePhone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number (Optional)',
                        hintText: 'Enter 10-digit phone number',
                        prefixIcon: Icon(
                          Icons.phone_rounded,
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
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Avatar / Accent color',
                        style: theme.textTheme.labelLarge,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _accentPicker(context),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Save Profile',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ─── Budget Section ───
            _buildSectionHeader(context, 'Budget'),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _budgetFormKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _budgetController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: false,
                        signed: false,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(7),
                      ],
                      validator: _validateBudget,
                      decoration: InputDecoration(
                        labelText: 'Monthly Budget',
                        hintText: 'Enter monthly budget',
                        prefixText: '$currency ',
                        prefixStyle: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w700,
                        ),
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
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _startingBalanceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: false,
                        signed: false,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      validator: _validateBudget,
                      decoration: InputDecoration(
                        labelText: 'Current Account Balance (Optional)',
                        hintText: 'Enter current account balance',
                        prefixText: '$currency ',
                        prefixStyle: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                        prefixIcon: Icon(
                          Icons.account_balance_wallet_rounded,
                          color: theme.colorScheme.secondary,
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
                    subtitle: 'Selected: $currency',
                    onTap: () => _showCurrencyPicker(context),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ─── Security Section ───
            _buildSectionHeader(context, 'Security'),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(0),
              child: Column(
                children: [
                  // Lock timeout selector
                  _buildSettingTile(
                    context,
                    icon: Icons.lock_clock,
                    iconColor: theme.colorScheme.primary,
                    title: 'Auto-lock timeout',
                    subtitle: '${ref.watch(lockTimeoutProvider)} minutes',
                    onTap: () async {
                      final options = <int>[0, 1, 5, 10, 15, 20, 30, 60];
                      final labels = ['Immediately', '1 min', '5 mins', '10 mins', '15 mins', '20 mins', '30 mins', '1 hour'];
                      final choice = await showDialog<int?>(
                        context: context,
                        builder: (ctx) {
                          return SimpleDialog(
                            title: const Text('Select auto-lock timeout'),
                            children: [
                              for (var i = 0; i < options.length; i++)
                                SimpleDialogOption(
                                  onPressed: () => Navigator.pop(ctx, options[i]),
                                  child: Text(labels[i]),
                                )
                            ],
                          );
                        },
                      );

                      if (choice != null) await ref.read(lockTimeoutProvider.notifier).setTimeoutMinutes(choice);
                    },
                    trailing: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.outline),
                  ),
                  _buildDivider(context),
                  Consumer(builder: (context, ref, _) {
                    // show biometric toggle only if device supports it
                    return FutureBuilder<bool>(
                      future: Future.value(_biometricAvailable),
                      builder: (ctx, snap) {
                        final available = snap.data ?? false;
                        if (!available) return const SizedBox.shrink();
                        final pinAuth = ref.watch(pinAuthProvider);
                        return _buildSettingTile(
                          context,
                          icon: Icons.fingerprint,
                          iconColor: theme.colorScheme.primary,
                          title: 'Biometric Login',
                          subtitle: pinAuth.isBiometricEnabled() ? 'Enabled' : 'Disabled',
                          onTap: () async {
                            final enabled = !pinAuth.isBiometricEnabled();
                            if (enabled) {
                              // check availability and enrollment
                              try {
                                final auth = LocalAuthentication();
                                final canCheck = await auth.canCheckBiometrics || await auth.isDeviceSupported();
                                final enrolled = (await auth.getAvailableBiometrics()).isNotEmpty;
                                if (!canCheck || !enrolled) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Biometric not available, please use PIN')));
                                  return;
                                }
                              } catch (_) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Biometric not available, please use PIN')));
                                return;
                              }
                            }

                            await ref.read(pinAuthProvider).setBiometricEnabled(enabled);
                            setState(() {});
                          },
                          trailing: Switch(
                            value: ref.watch(pinAuthProvider).isBiometricEnabled(),
                            onChanged: (v) async {
                              if (v) {
                                try {
                                  final auth = LocalAuthentication();
                                  final canCheck = await auth.canCheckBiometrics || await auth.isDeviceSupported();
                                  final enrolled = (await auth.getAvailableBiometrics()).isNotEmpty;
                                  if (!canCheck || !enrolled) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Biometric not available, please use PIN')));
                                    return;
                                  }
                                } catch (_) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Biometric not available, please use PIN')));
                                  return;
                                }
                              }
                              await ref.read(pinAuthProvider).setBiometricEnabled(v);
                              setState(() {});
                            },
                          ),
                        );
                      },
                    );
                  }),
                  _buildDivider(context),
                  _buildSettingTile(
                    context,
                    icon: Icons.lock_open,
                    iconColor: AppColors.debit,
                    title: 'Change PIN',
                    subtitle: 'Update your 4-digit PIN',
                    onTap: () async {
                      // ask current PIN then new PIN twice
                      final current = await showDialog<String?>(
                        context: context,
                        builder: (ctx) {
                          final controller = TextEditingController();
                          return AlertDialog(
                            title: const Text('Enter current PIN'),
                            content: TextField(controller: controller, keyboardType: TextInputType.number, obscureText: true, maxLength: 4, decoration: const InputDecoration(counterText: '')),
                            actions: [TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('OK'))],
                          );
                        },
                      );

                      if (current == null) return;
                      final ok = await ref.read(pinAuthProvider).verifyPin(current);
                      if (!context.mounted) return;
                      if (!ok) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incorrect current PIN')));
                        return;
                      }

                      final newPin1 = await showDialog<String?>(
                        context: context,
                        builder: (ctx) {
                          final controller = TextEditingController();
                          return AlertDialog(
                            title: const Text('Enter new PIN'),
                            content: TextField(controller: controller, keyboardType: TextInputType.number, obscureText: true, maxLength: 4, decoration: const InputDecoration(counterText: '')),
                            actions: [TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Next'))],
                          );
                        },
                      );
                      if (newPin1 == null || newPin1.length != 4) return;
                      if (!context.mounted) return;

                      final newPin2 = await showDialog<String?>(
                        context: context,
                        builder: (ctx) {
                          final controller = TextEditingController();
                          return AlertDialog(
                            title: const Text('Confirm new PIN'),
                            content: TextField(controller: controller, keyboardType: TextInputType.number, obscureText: true, maxLength: 4, decoration: const InputDecoration(counterText: '')),
                            actions: [TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Save'))],
                          );
                        },
                      );

                      if (newPin2 == null || newPin1 != newPin2) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PINs do not match')));
                        return;
                      }

                      await ref.read(pinAuthProvider).setPin(newPin1);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN updated')));
                    },
                    trailing: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.outline),
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

                ref.invalidate(allTransactionsProvider);
                ref.invalidate(allBudgetsProvider);
                ref.invalidate(monthlyBudgetProvider);
                ref.invalidate(userNameProvider);
                ref.invalidate(userPhoneProvider);
                ref.invalidate(accentColorValueProvider);
                ref.invalidate(currencySymbolProvider);
                ref.invalidate(startingBalanceProvider);

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
