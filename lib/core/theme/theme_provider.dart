import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme_registry.dart';

final appThemeIdProvider = StateNotifierProvider<AppThemeIdNotifier, AppThemeId>((ref) {
  return AppThemeIdNotifier();
});

class AppThemeIdNotifier extends StateNotifier<AppThemeId> {
  AppThemeIdNotifier() : super(ThemeRegistry.defaultTheme);

  void setTheme(AppThemeId theme) {
    state = theme;
  }
}
