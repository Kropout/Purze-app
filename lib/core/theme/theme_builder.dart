import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'design_spec.dart';

/// Builds Flutter [ThemeData] from a [DesignSpec] (parsed from DESIGN.md).
class ThemeBuilder {
  ThemeBuilder._();

  static ThemeData fromSpec(
    DesignSpec spec, {
    Brightness brightness = Brightness.dark,
  }) {
    final colors = spec.colors;
    final rounded = spec.rounded;
    final typography = spec.typography;
    final onSurface = colors.onSurface;
    final onSurfaceVariant = colors.onSurfaceVariant;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: colors.surface,
      colorScheme: colors.toColorScheme(brightness: brightness),
      textTheme: _buildTextTheme(typography, onSurface, onSurfaceVariant),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: _style(
          typography['headline-md'],
          onSurface,
          fallbackSize: 20,
          fallbackWeight: FontWeight.w600,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surfaceContainer,
        indicatorColor: colors.primaryContainer.withValues(alpha: 0.35),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colors.primary);
          }
          return IconThemeData(color: colors.outline);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final base = typography['label-sm'];
          final color = states.contains(WidgetState.selected)
              ? colors.primary
              : colors.outline;
          return _style(base, color, fallbackSize: 12, fallbackWeight: FontWeight.w500);
        }),
      ),
      cardTheme: CardThemeData(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.85),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rounded.lg),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceContainerHigh,
        selectedColor: colors.primaryContainer,
        labelStyle: _style(
          typography['label-md'],
          onSurface,
          fallbackSize: 13,
          fallbackWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rounded.full),
        ),
        side: BorderSide.none,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.6),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        hintStyle: _style(
          typography['body-sm'],
          colors.outline,
          fallbackSize: 14,
          fallbackWeight: FontWeight.w400,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: spec.spacing.gutter,
          vertical: spec.spacing.unit * 4,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: spec.spacing.gutter + spec.spacing.unit * 2,
            vertical: spec.spacing.unit * 4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(rounded.full),
          ),
          textStyle: _style(
            typography['label-md'],
            colors.onPrimary,
            fallbackSize: 15,
            fallbackWeight: FontWeight.w600,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: onSurface.withValues(alpha: 0.05),
        thickness: 1,
        space: 1,
      ),
      extensions: [DesignThemeExtension(spec: spec)],
    );
  }

  static TextTheme _buildTextTheme(
    Map<String, DesignTypographyStyle> typography,
    Color onSurface,
    Color onSurfaceVariant,
  ) {
    return TextTheme(
      displayLarge: _style(typography['headline-xl'], onSurface,
          fallbackSize: 48, fallbackWeight: FontWeight.w700),
      displayMedium: _style(typography['headline-lg'], onSurface,
          fallbackSize: 32, fallbackWeight: FontWeight.w600),
      displaySmall: _style(typography['headline-lg-mobile'], onSurface,
          fallbackSize: 28, fallbackWeight: FontWeight.w600),
      headlineLarge: _style(typography['headline-lg'], onSurface,
          fallbackSize: 32, fallbackWeight: FontWeight.w600),
      headlineMedium: _style(typography['headline-lg-mobile'], onSurface,
          fallbackSize: 28, fallbackWeight: FontWeight.w600),
      headlineSmall: _style(typography['headline-md'], onSurface,
          fallbackSize: 24, fallbackWeight: FontWeight.w600),
      titleLarge: _style(typography['headline-md'], onSurface,
          fallbackSize: 22, fallbackWeight: FontWeight.w600),
      titleMedium: _style(typography['label-md'], onSurface,
          fallbackSize: 16, fallbackWeight: FontWeight.w600),
      titleSmall: _style(typography['label-md'], onSurface,
          fallbackSize: 14, fallbackWeight: FontWeight.w500),
      bodyLarge: _style(typography['body-lg'], onSurface,
          fallbackSize: 18, fallbackWeight: FontWeight.w400),
      bodyMedium: _style(typography['body-md'], onSurface,
          fallbackSize: 16, fallbackWeight: FontWeight.w400),
      bodySmall: _style(typography['body-sm'], onSurfaceVariant,
          fallbackSize: 14, fallbackWeight: FontWeight.w400),
      labelLarge: _style(typography['label-md'], onSurface,
          fallbackSize: 14, fallbackWeight: FontWeight.w500),
      labelMedium: _style(typography['label-sm'], onSurface,
          fallbackSize: 12, fallbackWeight: FontWeight.w500),
      labelSmall: _style(typography['label-sm'], onSurfaceVariant,
          fallbackSize: 11, fallbackWeight: FontWeight.w500),
    );
  }

  static TextStyle _style(
    DesignTypographyStyle? token,
    Color color, {
    required double fallbackSize,
    required FontWeight fallbackWeight,
  }) {
    if (token == null) {
      return GoogleFonts.inter(
        fontSize: fallbackSize,
        fontWeight: fallbackWeight,
        color: color,
      );
    }

    final family = token.fontFamily.toLowerCase();
    final base = family == 'geist'
        ? GoogleFonts.inter(
            fontSize: token.fontSize,
            fontWeight: token.fontWeight,
            height: token.height,
            letterSpacing: token.letterSpacing,
            color: color,
          )
        : GoogleFonts.inter(
            fontSize: token.fontSize,
            fontWeight: token.fontWeight,
            height: token.height,
            letterSpacing: token.letterSpacing,
            color: color,
          );

    return base;
  }
}

/// Exposes raw DESIGN.md tokens on [ThemeData] for widgets that need spacing/radius.
class DesignThemeExtension extends ThemeExtension<DesignThemeExtension> {
  const DesignThemeExtension({required this.spec});

  final DesignSpec spec;

  DesignColors get colors => spec.colors;
  DesignRounded get rounded => spec.rounded;
  DesignSpacing get spacing => spec.spacing;

  @override
  DesignThemeExtension copyWith({DesignSpec? spec}) {
    return DesignThemeExtension(spec: spec ?? this.spec);
  }

  @override
  DesignThemeExtension lerp(ThemeExtension<DesignThemeExtension>? other, double t) {
    if (other is! DesignThemeExtension) return this;
    return t < 0.5 ? this : other;
  }
}

extension DesignThemeContext on BuildContext {
  DesignThemeExtension? get designTheme =>
      Theme.of(this).extension<DesignThemeExtension>();
}
