import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/constants/app_constants.dart';
import '../providers/app_providers.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  static const Color _accentTeal = Color(0xFF00BFA5);
  static const Color _bg = Color(0xFF050B0D);

  final LocalAuthentication _auth = LocalAuthentication();

  String _pin = '';
  String _error = '';
  Timer? _lockTicker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAuthenticate());
  }

  @override
  void dispose() {
    _lockTicker?.cancel();
    super.dispose();
  }

  void _startLockTicker() {
    _lockTicker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final pinAuth = ref.read(pinAuthProvider);
      if (pinAuth.isLocked()) {
        setState(() {
          _error = 'Locked for ${pinAuth.lockedSecondsRemaining()}s';
        });
        return;
      }

      _lockTicker?.cancel();
      _lockTicker = null;
      setState(() {
        _error = '';
      });
    });
  }

  Future<void> _maybeAuthenticate() async {
    final pinAuth = ref.read(pinAuthProvider);
    if (!pinAuth.isPinSet()) return;

    if (defaultTargetPlatform == TargetPlatform.android && pinAuth.isBiometricEnabled()) {
      try {
        final canCheck = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
        if (canCheck) {
          final enrolled = (await _auth.getAvailableBiometrics()).isNotEmpty;
          if (!enrolled) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Biometric not available, please use PIN')));
          } else {
            final didAuth = await _auth.authenticate(
              localizedReason: 'Authenticate to unlock Purze',
              options: const AuthenticationOptions(biometricOnly: true),
            );
            if (didAuth) {
              if (mounted) Navigator.of(context).pop();
              return;
            }
          }
        }
      } catch (_) {}
    }
  }

  void _addDigit(int digit) {
    final pinAuth = ref.read(pinAuthProvider);
    if (pinAuth.isLocked()) {
      setState(() => _error = 'Locked for ${pinAuth.lockedSecondsRemaining()}s');
      _startLockTicker();
      return;
    }

    if (_pin.length >= 4) return;

    setState(() {
      _error = '';
      _pin = '$_pin$digit';
    });

    if (_pin.length == 4) {
      _verifyPin();
    }
  }

  void _backspace() {
    final pinAuth = ref.read(pinAuthProvider);
    if (pinAuth.isLocked()) {
      setState(() => _error = 'Locked for ${pinAuth.lockedSecondsRemaining()}s');
      _startLockTicker();
      return;
    }

    if (_pin.isEmpty) return;
    setState(() {
      _error = '';
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  Future<void> _verifyPin() async {
    final pin = _pin;
    if (pin.length != 4) return;

    final pinAuth = ref.read(pinAuthProvider);
    if (pinAuth.isLocked()) {
      setState(() => _error = 'Locked for ${pinAuth.lockedSecondsRemaining()}s');
      _startLockTicker();
      return;
    }

    final ok = await pinAuth.verifyPin(pin);
    if (ok) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final nowLocked = pinAuth.isLocked();
    setState(() {
      _pin = '';
      _error = nowLocked
          ? 'Locked for ${pinAuth.lockedSecondsRemaining()}s'
          : 'Incorrect PIN';
    });

    if (nowLocked) {
      _startLockTicker();
    }
  }

  Future<void> _forgotPin() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red),
              const SizedBox(width: 8),
              Text('Warning', style: theme.textTheme.titleMedium),
            ],
          ),
          content: Text(
            'This will clear all your data and restart the app',
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Proceed'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final repo = ref.read(transactionRepositoryProvider);
      await repo.clearAllData();
      final settingsBox = Hive.box(AppConstants.settingsBox);
      await settingsBox.clear();
      await ref.read(hasOnboardedProvider.notifier).reset();
      if (mounted) {
        Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
      }
    }
  }

  Widget _pinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final filled = i < _pin.length;
        return Container(
          width: 16,
          height: 16,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? _accentTeal : Colors.transparent,
            border: Border.all(
              color: filled ? _accentTeal : Colors.white24,
              width: 1.5,
            ),
            boxShadow: filled
                ? [
                    BoxShadow(
                      color: _accentTeal.withValues(alpha: 0.35),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }

  Widget _keypadButton({required Widget child, required VoidCallback? onTap}) {
    return _KeyButton(
      accent: _accentTeal,
      onTap: onTap,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final confirmEnabled = _pin.length == 4;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Text(
                  'Enter PIN',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                _pinDots(),
                const SizedBox(height: 14),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: _error.isEmpty ? 0 : 1,
                  child: Text(
                    _error.isEmpty ? ' ' : _error,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.redAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 1.25,
                        children: [
                          for (final n in [1, 2, 3, 4, 5, 6, 7, 8, 9])
                            _keypadButton(
                              child: Text(
                                '$n',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              onTap: () => _addDigit(n),
                            ),
                          _keypadButton(
                            child: Icon(
                              Icons.backspace_outlined,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            onTap: _backspace,
                          ),
                          _keypadButton(
                            child: Text(
                              '0',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onTap: () => _addDigit(0),
                          ),
                          _keypadButton(
                            child: Icon(
                              Icons.check_rounded,
                              color: Colors.white.withValues(alpha: confirmEnabled ? 0.95 : 0.35),
                            ),
                            onTap: confirmEnabled ? _verifyPin : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _forgotPin,
                  child: Text(
                    'Forgot PIN',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white70,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white38,
                    ),
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

class _KeyButton extends StatelessWidget {
  final Color accent;
  final Widget child;
  final VoidCallback? onTap;

  const _KeyButton({required this.accent, required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        splashColor: accent.withValues(alpha: 0.22),
        highlightColor: accent.withValues(alpha: 0.10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: enabled ? Colors.white24 : Colors.white12,
              width: 1,
            ),
            color: Colors.white.withValues(alpha: 0.04),
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}
