import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive/hive.dart';
import '../../data/services/sms_importer.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../providers/app_providers.dart';
import '../widgets/glass_card.dart';
import '../widgets/ambient_background.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();

  final _nameFormKey = GlobalKey<FormState>();
  final _budgetFormKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _budgetController = TextEditingController();
  final _startingBalanceController = TextEditingController();

  int _step = 0;
  bool _requestingSms = false;

  int _accentColorValue = AppColors.primary.toARGB32();

  static const List<String> _currencyOptions = <String>['₹', r'$', '€', '£'];

  @override
  void initState() {
    super.initState();

    _nameController.text = ref.read(userNameProvider);
    _phoneController.text = ref.read(userPhoneProvider);

    final mbDouble = ref.read(monthlyBudgetProvider);
    _budgetController.text = mbDouble <= 0 ? '' : mbDouble.toStringAsFixed(0);

    _accentColorValue = ref.read(accentColorValueProvider);

    final sb = ref.read(startingBalanceProvider);
    _startingBalanceController.text = sb <= 0 ? '' : sb.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _budgetController.dispose();
    _startingBalanceController.dispose();
    super.dispose();
  }

  Future<void> _goNext() async {
    final next = (_step + 1).clamp(0, 6);
    await _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _goBack() async {
    final prev = (_step - 1).clamp(0, 6);
    await _pageController.animateToPage(
      prev,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
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

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    await ref.read(userNameProvider.notifier).setName(name);
    await ref.read(userPhoneProvider.notifier).setPhone(phone);
    await ref.read(accentColorValueProvider.notifier).setAccentColorValue(_accentColorValue);
  }

  Future<void> _saveMonthlyBudget() async {
    final raw = _budgetController.text.replaceAll(',', '').trim();
    final value = double.tryParse(raw) ?? 0;
    await ref.read(monthlyBudgetProvider.notifier).setBudget(value);
  }

  Future<void> _saveStartingBalance() async {
    final raw = _startingBalanceController.text.replaceAll(',', '').trim();
    final value = double.tryParse(raw) ?? 0;
    await ref.read(startingBalanceProvider.notifier).setStartingBalance(value);
  }

  Future<void> _requestSmsPermission({required bool allowSkip}) async {
    setState(() => _requestingSms = true);
    try {
      // On web, skip permission request (SMS not applicable)
      if (!Platform.isAndroid && !Platform.isIOS) {
        if (mounted) await _goNext();
        return;
      }

      final status = await Permission.sms.request();
      if (status.isGranted) {
        // On Android, import entire inbox after permission is granted
        if (Platform.isAndroid) {
          // show blocking import dialog
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) {
                final theme = Theme.of(ctx);
                return AlertDialog(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  content: SizedBox(
                    width: 220,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: theme.colorScheme.primary),
                        const SizedBox(height: 16),
                        Text('Importing your transaction history...', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          try {
            final repo = ref.read(transactionRepositoryProvider);
            final lastSync = Hive.box(AppConstants.settingsBox).get(AppConstants.lastSmsSyncKey) as int?;
            final importer = SmsImporter();
            final added = await importer.importEntireInbox(repo, sinceMillis: lastSync);
            // update last sync
            try {
              final box = Hive.box(AppConstants.settingsBox);
              await box.put(AppConstants.lastSmsSyncKey, DateTime.now().millisecondsSinceEpoch);
            } catch (_) {}

            // refresh providers
            ref.read(allTransactionsProvider.notifier).refresh();

            if (mounted && added > 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Imported $added transactions'),
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } catch (_) {
            // ignore import errors
          } finally {
            if (mounted) Navigator.of(context, rootNavigator: true).pop();
          }
        }

        if (mounted) await _goNext();
      } else if (allowSkip) {
        if (mounted) await _goNext();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('SMS permission denied. You can enable it later in Settings.'),
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (_) {
      if (allowSkip && mounted) await _goNext();
    } finally {
      if (mounted) setState(() => _requestingSms = false);
    }
  }

  Widget _stepHeader(BuildContext context, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      ],
    );
  }

  Widget _primaryButton({required String label, required VoidCallback? onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }

  Widget _page(Widget child) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        child: Align(
          alignment: Alignment.topCenter,
          child: child,
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencySymbolProvider);

    return AmbientBackground(
      child: Scaffold(
        body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Step ${_step + 1}/7',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (_step > 0)
                    TextButton(
                      onPressed: _goBack,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black54,
                      ),
                      child: const Text('Back'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _step = i),
                  children: [
                    // 1) Welcome
                    _page(
                      GlassCard(
                        showGlow: true,
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _stepHeader(
                              context,
                              'Welcome to Purze',
                              'Let\'s set up your account in under a minute.',
                            ),
                            const SizedBox(height: 24),
                            _primaryButton(
                              label: 'Get Started',
                              onPressed: _goNext,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 2) Profile
                    _page(
                      GlassCard(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _nameFormKey,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _stepHeader(
                                context,
                                'Your profile',
                                'Name is used for greeting. Phone is optional.',
                              ),
                              const SizedBox(height: 18),
                              TextFormField(
                                controller: _nameController,
                                textInputAction: TextInputAction.next,
                                maxLength: AppConstants.maxNameLength,
                                validator: _validateName,
                                decoration: const InputDecoration(
                                  hintText: 'Enter your name',
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
                                decoration: const InputDecoration(
                                  hintText: 'Phone number (optional)',
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Avatar / Accent color',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              const SizedBox(height: 10),
                              _accentPicker(context),
                              const SizedBox(height: 18),
                              Builder(
                                builder: (context) {
                                  final selectedCurrency = _currencyOptions.contains(currency)
                                      ? currency
                                      : AppConstants.defaultCurrencySymbol;
                                  return DropdownButtonFormField<String>(
                                    key: ValueKey(selectedCurrency),
                                    initialValue: selectedCurrency,
                                    items: [
                                      for (final s in _currencyOptions)
                                        DropdownMenuItem(
                                          value: s,
                                          child: Text('Currency: $s'),
                                        ),
                                    ],
                                    onChanged: (v) async {
                                      if (v == null) return;
                                      await ref.read(currencySymbolProvider.notifier).setSymbol(v);
                                    },
                                    decoration: const InputDecoration(
                                      hintText: 'Select currency',
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 18),
                              _primaryButton(
                                label: 'Continue',
                                onPressed: () async {
                                  final ok = _nameFormKey.currentState?.validate() ?? false;
                                  if (!ok) return;
                                  await _saveProfile();
                                  if (mounted) await _goNext();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 3) Set monthly budget
                    _page(
                      GlassCard(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _budgetFormKey,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _stepHeader(
                                context,
                                'Monthly budget',
                                'Set a budget in $currency. You can change it later.',
                              ),
                              const SizedBox(height: 18),
                              TextFormField(
                                controller: _budgetController,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.done,
                                validator: _validateBudget,
                                decoration: InputDecoration(
                                  prefixText: '$currency ',
                                  hintText: '0',
                                ),
                              ),
                              const SizedBox(height: 18),
                              _primaryButton(
                                label: 'Continue',
                                onPressed: () async {
                                  final ok = _budgetFormKey.currentState?.validate() ?? false;
                                  if (!ok) return;
                                  await _saveMonthlyBudget();
                                  if (mounted) await _goNext();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 4) Starting balance (Estimated available balance helper)
                    _page(
                      GlassCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _stepHeader(
                              context,
                              'Current Account Balance (₹)',
                              'This helps estimate your available balance. You can update it anytime in Settings.',
                            ),
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _startingBalanceController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              validator: _validateBudget,
                              decoration: InputDecoration(
                                prefixText: '$currency ',
                                hintText: '0',
                              ),
                            ),
                            const SizedBox(height: 18),
                            _primaryButton(
                              label: 'Continue',
                              onPressed: () async {
                                await _saveStartingBalance();
                                if (mounted) await _goNext();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 5) PIN setup
                    _page(
                      GlassCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _stepHeader(
                              context,
                              'Set a 4-digit PIN',
                              'Use a 4-digit PIN to secure your app. You can also enable biometrics later.',
                            ),
                            const SizedBox(height: 18),
                            Builder(builder: (ctx) {
                              final pin1 = TextEditingController();
                              final pin2 = TextEditingController();
                              return Column(
                                children: [
                                  TextField(controller: pin1, keyboardType: TextInputType.number, obscureText: true, maxLength: 4, decoration: const InputDecoration(hintText: 'Enter 4-digit PIN', counterText: '')),
                                  const SizedBox(height: 8),
                                  TextField(controller: pin2, keyboardType: TextInputType.number, obscureText: true, maxLength: 4, decoration: const InputDecoration(hintText: 'Confirm PIN', counterText: '')),
                                  const SizedBox(height: 12),
                                  _primaryButton(
                                    label: 'Save PIN',
                                    onPressed: () async {
                                      final p1 = pin1.text.trim();
                                      final p2 = pin2.text.trim();
                                      if (p1.length != 4 || p2.length != 4) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a 4-digit PIN')));
                                        return;
                                      }
                                      if (p1 != p2) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PINs do not match')));
                                        return;
                                      }
                                      await ref.read(pinAuthProvider).setPin(p1);
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN saved')));
                                      await _goNext();
                                    },
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                    ),

                    // 6) SMS permission
                    _page(
                      GlassCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _stepHeader(
                              context,
                              'SMS permission',
                              'We read UPI SMS to track transactions. Your data never leaves your device.',
                            ),
                            const SizedBox(height: 24),
                            _primaryButton(
                              label: _requestingSms ? 'Requesting…' : 'Allow SMS access',
                              onPressed: _requestingSms ? null : () => _requestSmsPermission(allowSkip: false),
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: TextButton(
                                onPressed: _requestingSms ? null : () => _requestSmsPermission(allowSkip: true),
                                child: const Text('Not now'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 5) Done
                    _page(
                      GlassCard(
                        showGlow: true,
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _stepHeader(
                              context,
                              'All set!',
                              'Welcome to Purze.',
                            ),
                            const SizedBox(height: 24),
                            _primaryButton(
                              label: 'Done',
                              onPressed: () async {
                                await ref.read(hasOnboardedProvider.notifier).complete();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
  );
}
}
