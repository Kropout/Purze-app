import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import 'main_shell.dart';
import 'onboarding_screen.dart';
import 'lock_screen.dart';

class AppEntry extends ConsumerStatefulWidget {
  const AppEntry({super.key});

  @override
  ConsumerState<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends ConsumerState<AppEntry> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowLock());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final pinAuth = ref.read(pinAuthProvider);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // record last active time
      pinAuth.updateLastActive();
    }

    if (state == AppLifecycleState.resumed) {
      _maybeShowLock();
    }
  }

  void _maybeShowLock() {
    final hasOnboarded = ref.read(hasOnboardedProvider);
    final pinAuth = ref.read(pinAuthProvider);
    if (!hasOnboarded) return;
    if (!pinAuth.isPinSet()) return;

    final timeoutMinutes = ref.read(lockTimeoutProvider);
    // Immediately option
    if (timeoutMinutes == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LockScreen()));
      });
      return;
    }

    final last = pinAuth.getLastActive();
    if (last == null) {
      // No record — set now and don't lock
      pinAuth.updateLastActive();
      return;
    }

    final diff = DateTime.now().difference(last);
    if (diff.inMinutes >= timeoutMinutes) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LockScreen()));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasOnboarded = ref.watch(hasOnboardedProvider);
    return hasOnboarded ? const MainShell() : const OnboardingScreen();
  }
}
