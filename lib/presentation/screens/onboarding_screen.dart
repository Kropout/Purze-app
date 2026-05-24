import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/constants/app_constants.dart';
import '../providers/app_providers.dart';
import '../widgets/glass_card.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  final _budgetController = TextEditingController();

  int _step = 0;
  bool _requestingSms = false;

  @override
  void initState() {
    super.initState();
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
    _pageController.dispose();
    _nameController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _goNext() async {
    final next = (_step + 1).clamp(0, 4);
    await _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _goBack() async {
    final prev = (_step - 1).clamp(0, 4);
    await _pageController.animateToPage(
      prev,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    try {
      final box = Hive.box(AppConstants.settingsBox);
      await box.put(AppConstants.userNameKey, name);
    } catch (_) {}
  }

  Future<void> _saveMonthlyBudget() async {
    final raw = _budgetController.text.replaceAll(',', '').trim();
    final value = double.tryParse(raw) ?? 0;
    await ref.read(monthlyBudgetProvider.notifier).setBudget(value);
  }

  Future<void> _requestSmsPermission({required bool allowSkip}) async {
    setState(() => _requestingSms = true);
    try {
      final status = await Permission.sms.request();
      if (status.isGranted) {
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
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.outline),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    'Step ${_step + 1}/5',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: Theme.of(context).colorScheme.outline),
                  ),
                  if (_step > 0)
                    TextButton(
                      onPressed: _goBack,
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
                    GlassCard(
                      showGlow: true,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _stepHeader(
                            context,
                            'Welcome to Purze',
                            'Let\'s set up your account in under a minute.',
                          ),
                          const Spacer(),
                          _primaryButton(
                            label: 'Get Started',
                            onPressed: _goNext,
                          ),
                        ],
                      ),
                    ),

                    // 2) Enter name
                    GlassCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _stepHeader(
                            context,
                            'Your name',
                            'This helps us personalize your home screen.',
                          ),
                          const SizedBox(height: 18),
                          TextField(
                            controller: _nameController,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              hintText: 'Enter your name',
                            ),
                          ),
                          const Spacer(),
                          _primaryButton(
                            label: 'Continue',
                            onPressed: () async {
                              await _saveName();
                              if (mounted) await _goNext();
                            },
                          ),
                        ],
                      ),
                    ),

                    // 3) Set monthly budget
                    GlassCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _stepHeader(
                            context,
                            'Monthly budget',
                            'Set a budget in ₹. You can change it later.',
                          ),
                          const SizedBox(height: 18),
                          TextField(
                            controller: _budgetController,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              prefixText: '₹ ',
                              hintText: '0',
                            ),
                          ),
                          const Spacer(),
                          _primaryButton(
                            label: 'Continue',
                            onPressed: () async {
                              await _saveMonthlyBudget();
                              if (mounted) await _goNext();
                            },
                          ),
                        ],
                      ),
                    ),

                    // 4) SMS permission
                    GlassCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _stepHeader(
                            context,
                            'SMS permission',
                            'We read UPI SMS to track transactions. Your data never leaves your device.',
                          ),
                          const Spacer(),
                          _primaryButton(
                            label: _requestingSms ? 'Requesting…' : 'Allow SMS access',
                            onPressed: _requestingSms
                                ? null
                                : () => _requestSmsPermission(allowSkip: false),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: TextButton(
                              onPressed: _requestingSms
                                  ? null
                                  : () => _requestSmsPermission(allowSkip: true),
                              child: const Text('Not now'),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 5) Done
                    GlassCard(
                      showGlow: true,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _stepHeader(
                            context,
                            'All set!',
                            'Welcome to Purze.',
                          ),
                          const Spacer(),
                          _primaryButton(
                            label: 'Done',
                            onPressed: () async {
                              await ref.read(hasOnboardedProvider.notifier).complete();
                            },
                          ),
                        ],
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
    );
  }
}
