import 'package:flutter/material.dart';

import 'design_spec.dart';
import 'themes/luminous_obsidian.tokens.dart';
import 'themes/luminous_obsidian_theme.dart';
import 'app_theme.dart';

/// Identifies a design-system theme backed by a DESIGN.md file.
enum AppThemeId {
  deepForest,
  luminousObsidian,
}

/// Resolves [ThemeData] and [DesignSpec] for registered themes.
class ThemeRegistry {
  ThemeRegistry._();

  static const AppThemeId defaultTheme = AppThemeId.deepForest;

  static DesignSpec specFor(AppThemeId id) {
    switch (id) {
      case AppThemeId.deepForest:
        return LuminousObsidianTokens.spec; // Fallback spec, not used for styling widgets
      case AppThemeId.luminousObsidian:
        return LuminousObsidianTokens.spec;
    }
  }

  static ThemeData themeFor(
    AppThemeId id, {
    required Brightness brightness,
  }) {
    switch (id) {
      case AppThemeId.deepForest:
        return brightness == Brightness.dark
            ? AppTheme.darkTheme
            : AppTheme.lightTheme;
      case AppThemeId.luminousObsidian:
        return brightness == Brightness.dark
            ? LuminousObsidianTheme.dark
            : AppTheme.lightTheme;
    }
  }

  static String displayName(AppThemeId id) {
    switch (id) {
      case AppThemeId.deepForest:
        return 'Deep Forest';
      case AppThemeId.luminousObsidian:
        return LuminousObsidianTokens.name;
    }
  }
}
