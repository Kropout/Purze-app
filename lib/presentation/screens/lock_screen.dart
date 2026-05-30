import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';
import '../providers/app_providers.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  final TextEditingController _pinController = TextEditingController();
  String _error = ''; 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAuthenticate());
  }

  Future<void> _maybeAuthenticate() async {
    final pinAuth = ref.read(pinAuthProvider);
    if (!pinAuth.isPinSet()) return; // nothing to do

    if (defaultTargetPlatform == TargetPlatform.android && pinAuth.isBiometricEnabled()) {
      try {
        final canCheck = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
        if (canCheck) {
          final didAuth = await _auth.authenticate(
            localizedReason: 'Authenticate to unlock Purze',
            options: const AuthenticationOptions(biometricOnly: true),
          );
          if (didAuth) {
            if (mounted) Navigator.of(context).pop();
            return;
          }
        }
      } catch (_) {}
    }

    return;
  }

  Future<void> _verifyPin() async {
    final pin = _pinController.text.trim();
    if (pin.length != 4) return;
    final pinAuth = ref.read(pinAuthProvider);
    if (pinAuth.isLocked()) {
      setState(() => _error = 'Locked for ${pinAuth.lockedSecondsRemaining()}s');
      return;
    }

    final ok = await pinAuth.verifyPin(pin);
    if (ok) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    setState(() {
      _error = 'Incorrect PIN';
      _pinController.clear();
    });
  }

  Future<void> _forgotPin() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [const Icon(Icons.warning_amber_rounded, color: Colors.red), const SizedBox(width: 8), Text('Warning', style: theme.textTheme.titleMedium)]),
          content: Text('This will clear all your data and restart the app', style: theme.textTheme.bodyMedium),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Proceed'))],
        );
      },
    );

    if (confirm == true) {
      // clear data similar to Settings clear
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: theme.colorScheme.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Enter PIN', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    decoration: InputDecoration(counterText: ''),
                    onSubmitted: (_) => _verifyPin(),
                  ),
                  const SizedBox(height: 8),
                  if (_error.isNotEmpty) Text(_error, style: theme.textTheme.bodySmall?.copyWith(color: Colors.red)),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _verifyPin, child: const Text('Unlock')),
                  const SizedBox(height: 8),
                  TextButton(onPressed: _forgotPin, child: const Text('Forgot PIN')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }
}
