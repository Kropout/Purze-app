import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import 'main_shell.dart';
import 'onboarding_screen.dart';

class AppEntry extends ConsumerWidget {
  const AppEntry({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasOnboarded = ref.watch(hasOnboardedProvider);
    return hasOnboarded ? const MainShell() : const OnboardingScreen();
  }
}
