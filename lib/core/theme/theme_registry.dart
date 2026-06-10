import 'package:flutter/material.dart';

import 'design_spec.dart';
import 'themes/luminous_obsidian.tokens.dart';
import 'themes/luminous_obsidian_theme.dart';
import 'app_theme.dart';

/// Identifies a design-system theme backed by a DESIGN.md file.
enum AppThemeId {
  luminousObsidian,
}

/// Resolves [ThemeData] and [DesignSpec] for registered themes.
class ThemeRegistry {
  ThemeRegistry._();

  static const AppThemeId defaultTheme = AppThemeId.luminousObsidian;

  static DesignSpec specFor(AppThemeId id) {
    switch (id) {
      case AppThemeId.luminousObsidian:
        return LuminousObsidianTokens.spec;
    }
  }

  static ThemeData themeFor(
    AppThemeId id, {
    required Brightness brightness,
  }) {
    switch (id) {
      case AppThemeId.luminousObsidian:
        return brightness == Brightness.dark
            ? LuminousObsidianTheme.dark
            : AppTheme.lightTheme;
    }
  }

  static String displayName(AppThemeId id) {
    switch (id) {
      case AppThemeId.luminousObsidian:
        return LuminousObsidianTokens.name;
    }
  }
}
