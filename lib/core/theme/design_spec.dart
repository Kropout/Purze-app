import 'package:flutter/material.dart';

/// Parsed color tokens from a DESIGN.md frontmatter `colors:` block.
///
/// Keys use camelCase (e.g. `surface-container-high` → [surfaceContainerHigh]).
class DesignColors {
  const DesignColors({
    required this.surface,
    required this.surfaceDim,
    required this.surfaceBright,
    required this.surfaceContainerLowest,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.inverseSurface,
    required this.inverseOnSurface,
    required this.outline,
    required this.outlineVariant,
    required this.surfaceTint,
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.inversePrimary,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.tertiary,
    required this.onTertiary,
    required this.tertiaryContainer,
    required this.onTertiaryContainer,
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.primaryFixed,
    required this.primaryFixedDim,
    required this.onPrimaryFixed,
    required this.onPrimaryFixedVariant,
    required this.secondaryFixed,
    required this.secondaryFixedDim,
    required this.onSecondaryFixed,
    required this.onSecondaryFixedVariant,
    required this.tertiaryFixed,
    required this.tertiaryFixedDim,
    required this.onTertiaryFixed,
    required this.onTertiaryFixedVariant,
    required this.background,
    required this.onBackground,
    required this.surfaceVariant,
  });

  final Color surface;
  final Color surfaceDim;
  final Color surfaceBright;
  final Color surfaceContainerLowest;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color inverseSurface;
  final Color inverseOnSurface;
  final Color outline;
  final Color outlineVariant;
  final Color surfaceTint;
  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color inversePrimary;
  final Color secondary;
  final Color onSecondary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color tertiary;
  final Color onTertiary;
  final Color tertiaryContainer;
  final Color onTertiaryContainer;
  final Color error;
  final Color onError;
  final Color errorContainer;
  final Color onErrorContainer;
  final Color primaryFixed;
  final Color primaryFixedDim;
  final Color onPrimaryFixed;
  final Color onPrimaryFixedVariant;
  final Color secondaryFixed;
  final Color secondaryFixedDim;
  final Color onSecondaryFixed;
  final Color onSecondaryFixedVariant;
  final Color tertiaryFixed;
  final Color tertiaryFixedDim;
  final Color onTertiaryFixed;
  final Color onTertiaryFixedVariant;
  final Color background;
  final Color onBackground;
  final Color surfaceVariant;

  ColorScheme toColorScheme({Brightness brightness = Brightness.dark}) {
    return ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: secondary,
      onSecondary: onSecondary,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: onSecondaryContainer,
      tertiary: tertiary,
      onTertiary: onTertiary,
      tertiaryContainer: tertiaryContainer,
      onTertiaryContainer: onTertiaryContainer,
      error: error,
      onError: onError,
      errorContainer: errorContainer,
      onErrorContainer: onErrorContainer,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: outlineVariant,
      inverseSurface: inverseSurface,
      onInverseSurface: inverseOnSurface,
      inversePrimary: inversePrimary,
      surfaceContainerHighest: surfaceContainerHighest,
      surfaceContainerHigh: surfaceContainerHigh,
      surfaceContainer: surfaceContainer,
      surfaceContainerLow: surfaceContainerLow,
      surfaceContainerLowest: surfaceContainerLowest,
      surfaceBright: surfaceBright,
      surfaceDim: surfaceDim,
      surfaceTint: surfaceTint,
    );
  }
}

/// A single typography token from DESIGN.md `typography:`.
class DesignTypographyStyle {
  const DesignTypographyStyle({
    required this.fontFamily,
    required this.fontSize,
    required this.fontWeight,
    required this.lineHeight,
    this.letterSpacing,
  });

  final String fontFamily;
  final double fontSize;
  final FontWeight fontWeight;
  final double lineHeight;
  final double? letterSpacing;

  double get height => lineHeight / fontSize;
}

/// Border-radius tokens from DESIGN.md `rounded:` (rem → logical px at 16px base).
class DesignRounded {
  const DesignRounded({
    required this.sm,
    required this.defaultRadius,
    required this.md,
    required this.lg,
    required this.xl,
    required this.full,
  });

  final double sm;
  final double defaultRadius;
  final double md;
  final double lg;
  final double xl;
  final double full;
}

/// Spacing tokens from DESIGN.md `spacing:`.
class DesignSpacing {
  const DesignSpacing({
    required this.unit,
    required this.gutter,
    required this.marginDesktop,
    required this.marginMobile,
    required this.containerMax,
  });

  final double unit;
  final double gutter;
  final double marginDesktop;
  final double marginMobile;
  final double containerMax;
}

/// Complete design-system definition parsed from a DESIGN.md file.
class DesignSpec {
  const DesignSpec({
    required this.name,
    required this.colors,
    required this.typography,
    required this.rounded,
    required this.spacing,
  });

  final String name;
  final DesignColors colors;
  final Map<String, DesignTypographyStyle> typography;
  final DesignRounded rounded;
  final DesignSpacing spacing;
}

/// Parses hex strings from DESIGN.md (`#0f141b` or `0f141b`).
Color designColor(String hex) {
  var value = hex.trim();
  if (value.startsWith('#')) value = value.substring(1);
  if (value.length == 6) value = 'FF$value';
  return Color(int.parse(value, radix: 16));
}

/// Converts kebab-case YAML keys to camelCase Dart identifiers.
String designKeyToCamelCase(String key) {
  final parts = key.split('-');
  if (parts.isEmpty) return key;
  return parts.first +
      parts.skip(1).map((p) => p.isEmpty ? '' : p[0].toUpperCase() + p.substring(1)).join();
}

/// Parses rem values from DESIGN.md (`0.5rem` → 8.0 at 16px base).
double designRem(String value) {
  final trimmed = value.trim();
  if (trimmed.endsWith('rem')) {
    return double.parse(trimmed.replaceAll('rem', '').trim()) * 16;
  }
  if (trimmed.endsWith('px')) {
    return double.parse(trimmed.replaceAll('px', '').trim());
  }
  return double.parse(trimmed);
}

/// Parses font weight strings (`'700'`, `'600'`).
FontWeight designFontWeight(String value) {
  final weight = int.parse(value.replaceAll("'", '').trim());
  return FontWeight.values.firstWhere(
    (w) => w.value == weight,
    orElse: () => FontWeight.w400,
  );
}
