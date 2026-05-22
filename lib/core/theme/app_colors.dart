import 'package:flutter/material.dart';

/// Purze Design System Colors — "The Liquid Vault"
/// Derived from the Stitch design system with deep oceanic teals
class AppColors {
  AppColors._();

  // ─── Primary Palette ───
  static const Color primary = Color(0xFF66D9CC);
  static const Color primaryContainer = Color(0xFF004C46);
  static const Color onPrimary = Color(0xFF003732);
  static const Color onPrimaryContainer = Color(0xFF4DC2B6);
  static const Color primaryFixed = Color(0xFF84F5E8);
  static const Color primaryFixedDim = Color(0xFF66D9CC);

  // ─── Secondary Palette ───
  static const Color secondary = Color(0xFF94D3C1);
  static const Color secondaryContainer = Color(0xFF0B5345);
  static const Color onSecondary = Color(0xFF00382E);
  static const Color onSecondaryContainer = Color(0xFF86C5B3);

  // ─── Tertiary (Accent/Coral) ───
  static const Color tertiary = Color(0xFFFFB5A1);
  static const Color tertiaryContainer = Color(0xFF693527);
  static const Color onTertiary = Color(0xFF512216);
  static const Color onTertiaryContainer = Color(0xFFE89F8C);

  // ─── Surface Hierarchy (Tonal Layering) ───
  static const Color surface = Color(0xFF001712);
  static const Color surfaceBright = Color(0xFF1F3F38);
  static const Color surfaceContainer = Color(0xFF03251E);
  static const Color surfaceContainerHigh = Color(0xFF0F2F29);
  static const Color surfaceContainerHighest = Color(0xFF1B3A33);
  static const Color surfaceContainerLow = Color(0xFF00201A);
  static const Color surfaceContainerLowest = Color(0xFF00110D);
  static const Color surfaceDim = Color(0xFF001712);
  static const Color surfaceTint = Color(0xFF66D9CC);
  static const Color surfaceVariant = Color(0xFF1B3A33);

  // ─── On-Surface (Text/Icons) ───
  static const Color onSurface = Color(0xFFC7EAE0);
  static const Color onSurfaceVariant = Color(0xFFBFC9C4);
  static const Color onBackground = Color(0xFFC7EAE0);
  static const Color background = Color(0xFF001712);

  // ─── Outline ───
  static const Color outline = Color(0xFF89938F);
  static const Color outlineVariant = Color(0xFF3F4945);

  // ─── Error ───
  static const Color error = Color(0xFFFFB4AB);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onError = Color(0xFF690005);
  static const Color onErrorContainer = Color(0xFFFFDAD6);

  // ─── Inverse ───
  static const Color inverseSurface = Color(0xFFC7EAE0);
  static const Color inverseOnSurface = Color(0xFF16362F);
  static const Color inversePrimary = Color(0xFF006A62);

  // ─── Semantic Colors ───
  static const Color debit = Color(0xFFFF6B6B);
  static const Color credit = Color(0xFF66D9CC);
  static const Color shimmer = Color(0x1AFFFFFF);

  // ─── Category Colors ───
  static const Color foodColor = Color(0xFFFF8A65);
  static const Color travelColor = Color(0xFF64B5F6);
  static const Color shoppingColor = Color(0xFFBA68C8);
  static const Color billsColor = Color(0xFFFFD54F);
  static const Color entertainmentColor = Color(0xFFE57373);
  static const Color healthColor = Color(0xFF81C784);
  static const Color otherColor = Color(0xFF90A4AE);

  // ─── Gradient for Primary CTA ───
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryContainer],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F2F29),
      Color(0xFF001712),
    ],
  );

  // ─── Iridescent & Glass Highlights ───
  static const Color glassHighlight = Color(0x33FFFFFF);
  static const Color glassHighlightDim = Color(0x05FFFFFF);
  
  static const List<Color> iridescentColors = [
    Color(0x99FFFFFF), // pure light highlight
    Color(0x6666D9CC), // primary (cyan-teal)
    Color(0x4494D3C1), // secondary (emerald)
    Color(0x66FFB5A1), // tertiary (coral highlight)
    Color(0x33FFFFFF), // trailing soft highlight
  ];

  // ─── Light Mode Surface & Backgrounds (Soft slate-teal off-white) ───
  static const Color lightSurface = Color(0xFFF2F7F5);
  static const Color lightSurfaceDim = Color(0xFFE6ECE9);
  static const Color lightSurfaceBright = Color(0xFFFCFDFD);
  static const Color lightSurfaceContainer = Color(0xFFE9F1EE);
  static const Color lightSurfaceContainerLow = Color(0xFFEDF4F1);
  static const Color lightSurfaceContainerLowest = Color(0xFFF6FAF8);
  static const Color lightSurfaceContainerHigh = Color(0xFFDFE8E5);
  static const Color lightSurfaceContainerHighest = Color(0xFFD4DDD9);

  // ─── Light Mode On-Surface (Text/Icons) ───
  static const Color lightOnSurface = Color(0xFF0D2521);
  static const Color lightOnSurfaceVariant = Color(0xFF3F4E4A);

  // ─── Light Mode Primary Palette (Readable deeper teal contrast) ───
  static const Color lightPrimary = Color(0xFF006A62);
  static const Color lightPrimaryContainer = Color(0xFF84F5E8);
  static const Color lightOnPrimary = Colors.white;
  static const Color lightOnPrimaryContainer = Color(0xFF00201C);

  // ─── Light Mode Secondary Palette ───
  static const Color lightSecondary = Color(0xFF0B5345);
  static const Color lightSecondaryContainer = Color(0xFF94D3C1);
  static const Color lightOnSecondary = Colors.white;
  static const Color lightOnSecondaryContainer = Color(0xFF002018);

  // ─── Light Mode Tertiary Palette ───
  static const Color lightTertiary = Color(0xFF9C4330);
  static const Color lightTertiaryContainer = Color(0xFFFFB5A1);
  static const Color lightOnTertiary = Colors.white;
  static const Color lightOnTertiaryContainer = Color(0xFF3E0400);

  // ─── Light Mode Outline ───
  static const Color lightOutline = Color(0xFF6F7975);
  static const Color lightOutlineVariant = Color(0xFFBFCBC7);
}
