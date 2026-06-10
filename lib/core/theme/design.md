# Purze Theme System

Themes are defined in **DESIGN.md** files — designers add or edit themes without writing Dart.

## Authoritative source

The project root [`DESIGN.md`](../../DESIGN.md) documents **Luminous Obsidian** with:

- `colors` — MD3 palette hex values
- `typography` — Geist (headings/labels) + Inter (body)
- `rounded` — border radii (`rem` → 16px base)
- `spacing` — 4px grid, gutters, margins

Human-readable brand guidelines follow the YAML frontmatter in the same file.

## Architecture

```
DESIGN.md                    ← designer edits this
    ↓  dart run tool/generate_theme.dart
lib/core/theme/themes/
  luminous_obsidian.tokens.dart   ← generated DesignSpec
  luminous_obsidian_theme.dart    ← thin ThemeData wrapper
lib/core/theme/
  design_spec.dart           ← token models
  theme_builder.dart         ← builds ThemeData from DesignSpec
  theme_registry.dart        ← maps theme IDs → specs/themes
  app_theme.dart             ← app entry (dark = Luminous Obsidian)
  app_colors.dart            ← widget palette + semantic colors
```

## Adding a new theme

1. Create a new DESIGN file, e.g. `themes/deep_forest/DESIGN.md`, using the same YAML frontmatter structure as the root `DESIGN.md`.
2. Run code generation:

   ```bash
   dart run tool/generate_theme.dart themes/deep_forest/DESIGN.md
   ```

   This writes `lib/core/theme/themes/deep_forest.tokens.dart`.

3. Add a thin wrapper (one-time Dart boilerplate):

   ```dart
   // lib/core/theme/themes/deep_forest_theme.dart
   class DeepForestTheme {
     static ThemeData get dark =>
         ThemeBuilder.fromSpec(DeepForestTokens.spec);
   }
   ```

4. Register the theme in `theme_registry.dart` (`AppThemeId` + switch cases).

5. Expose it in the settings theme picker (when implemented).

## Regenerating after DESIGN.md changes

Whenever colors, typography, spacing, or radii change in `DESIGN.md`:

```bash
dart run tool/generate_theme.dart DESIGN.md
```

Do **not** hand-edit `*.tokens.dart` files — they are generated.

## Widget access to tokens

- **ThemeData:** `Theme.of(context)` (built by `ThemeBuilder`)
- **Raw spec:** `context.designTheme?.spec` via `DesignThemeExtension`
- **Direct colors:** `AppColors.primary` (delegates to active palette)

Semantic colors (debit/credit, category chips) live in `app_colors.dart` because they are app-specific, not part of the design-system MD3 palette.
