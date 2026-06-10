import 'package:flutter/material.dart';
import '../theme_builder.dart';
import 'luminous_obsidian.tokens.dart';

/// Flutter theme for the "Luminous Obsidian" design system (see DESIGN.md).
class LuminousObsidianTheme {
  static const Color primary = Color(0xFFE0E0E0);

  static ThemeData get dark => ThemeBuilder.fromSpec(
        LuminousObsidianTokens.spec,
        brightness: Brightness.dark,
      );
}

