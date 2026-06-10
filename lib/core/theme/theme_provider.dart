import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../constants/app_constants.dart';
import 'theme_registry.dart';

final appThemeIdProvider = StateNotifierProvider<AppThemeIdNotifier, AppThemeId>((ref) {
  return AppThemeIdNotifier();
});

class AppThemeIdNotifier extends StateNotifier<AppThemeId> {
  AppThemeIdNotifier() : super(_readInitial());

  static AppThemeId _readInitial() {
    try {
      final box = Hive.box(AppConstants.settingsBox);
      final themeIndex = box.get('selectedThemeId') as int?;
      if (themeIndex != null && themeIndex >= 0 && themeIndex < AppThemeId.values.length) {
        return AppThemeId.values[themeIndex];
      }
    } catch (_) {}
    return ThemeRegistry.defaultTheme;
  }

  Future<void> setTheme(AppThemeId theme) async {
    state = theme;
    try {
      final box = Hive.box(AppConstants.settingsBox);
      await box.put('selectedThemeId', theme.index);
    } catch (_) {}
  }
}
