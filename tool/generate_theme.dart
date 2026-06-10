// ignore_for_file: avoid_print

import 'dart:io';

/// Generates Flutter theme token files from DESIGN.md frontmatter.
///
/// Usage:
///   dart run tool/generate_theme.dart [path/to/DESIGN.md]
///
/// Output:
///   lib/core/theme/themes/<snake_case_name>.tokens.dart
void main(List<String> args) {
  final inputPath = args.isNotEmpty ? args.first : 'DESIGN.md';
  final inputFile = File(inputPath);
  if (!inputFile.existsSync()) {
    stderr.writeln('File not found: $inputPath');
    exit(1);
  }

  final content = inputFile.readAsStringSync();
  final frontmatter = _extractFrontmatter(content);
  if (frontmatter == null) {
    stderr.writeln('No YAML frontmatter found in $inputPath');
    exit(1);
  }

  final name = _scalar(frontmatter, 'name');
  if (name == null || name.isEmpty) {
    stderr.writeln('Missing `name` in DESIGN.md frontmatter');
    exit(1);
  }

  final snakeName = _toSnakeCase(name);
  final classPrefix = _toPascalCase(snakeName);
  final colorsBlock = _block(frontmatter, 'colors');
  final typographyStyles = _typographyStyles(frontmatter);
  final roundedBlock = _block(frontmatter, 'rounded');
  final spacingBlock = _block(frontmatter, 'spacing');

  final buffer = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT EDIT BY HAND')
    ..writeln('// Source: $inputPath')
    ..writeln('// Theme: $name')
    ..writeln('// Regenerate: dart run tool/generate_theme.dart $inputPath')
    ..writeln()
    ..writeln("import 'package:flutter/material.dart';")
    ..writeln("import '../design_spec.dart';")
    ..writeln()
    ..writeln('/// Color + layout tokens for "$name".')
    ..writeln('class ${classPrefix}Tokens {')
    ..writeln('  ${classPrefix}Tokens._();')
    ..writeln()
    ..writeln("  static const String name = '$name';")
    ..writeln()
    ..writeln('  static const DesignSpec spec = DesignSpec(')
    ..writeln("    name: '$name',")
    ..writeln('    colors: const DesignColors(');

  for (final entry in _orderedColorKeys) {
    final hex = colorsBlock[entry.key];
    if (hex == null) {
      stderr.writeln('Warning: missing color `${entry.key}`');
      continue;
    }
    buffer.writeln('      ${entry.field}: ${_colorLiteral(hex)},');
  }

  buffer
    ..writeln('    ),')
    ..writeln('    typography: {');

  for (final entry in typographyStyles.entries) {
    final style = entry.value;
    buffer.writeln("      '${entry.key}': DesignTypographyStyle(");
    buffer.writeln("        fontFamily: '${style['fontFamily'] ?? 'Inter'}',");
    buffer.writeln('        fontSize: ${_parsePx(style['fontSize'] ?? '16px')},');
    buffer.writeln('        fontWeight: ${_fontWeightLiteral(style['fontWeight'] ?? '400')},');
    buffer.writeln('        lineHeight: ${_parsePx(style['lineHeight'] ?? '24px')},');
    final letterSpacing = style['letterSpacing'];
    if (letterSpacing != null) {
      buffer.writeln('        letterSpacing: ${_parseEm(letterSpacing)},');
    }
    buffer.writeln('      ),');
  }

  buffer
    ..writeln('    },')
    ..writeln('    rounded: const DesignRounded(')
    ..writeln('      sm: ${_remLiteral(roundedBlock['sm'] ?? '0.25rem')},')
    ..writeln('      defaultRadius: ${_remLiteral(roundedBlock['DEFAULT'] ?? '0.5rem')},')
    ..writeln('      md: ${_remLiteral(roundedBlock['md'] ?? '0.75rem')},')
    ..writeln('      lg: ${_remLiteral(roundedBlock['lg'] ?? '1rem')},')
    ..writeln('      xl: ${_remLiteral(roundedBlock['xl'] ?? '1.5rem')},')
    ..writeln('      full: ${_remLiteral(roundedBlock['full'] ?? '9999px')},')
    ..writeln('    ),')
    ..writeln('    spacing: const DesignSpacing(')
    ..writeln('      unit: ${_parsePx(spacingBlock['unit'] ?? '4px')},')
    ..writeln('      gutter: ${_parsePx(spacingBlock['gutter'] ?? '24px')},')
    ..writeln('      marginDesktop: ${_parsePx(spacingBlock['margin-desktop'] ?? '64px')},')
    ..writeln('      marginMobile: ${_parsePx(spacingBlock['margin-mobile'] ?? '20px')},')
    ..writeln('      containerMax: ${_parsePx(spacingBlock['container-max'] ?? '1280px')},')
    ..writeln('    ),')
    ..writeln('  );')
    ..writeln('}');

  final outputPath = 'lib/core/theme/themes/$snakeName.tokens.dart';
  File(outputPath).writeAsStringSync(buffer.toString());
  print('Generated $outputPath');
}

String? _extractFrontmatter(String content) {
  if (!content.startsWith('---')) return null;
  final end = content.indexOf('\n---', 3);
  if (end == -1) return null;
  return content.substring(4, end);
}

String? _scalar(String yaml, String key) {
  final match = RegExp('^$key:\\s*(.+)\$', multiLine: true).firstMatch(yaml);
  return match?.group(1)?.trim();
}

Map<String, String> _block(String yaml, String key) {
  final lines = yaml.split('\n');
  final result = <String, String>{};
  var inBlock = false;
  var indent = 0;

  for (final line in lines) {
    if (!inBlock) {
      if (line.trim() == '$key:') {
        inBlock = true;
        indent = line.indexOf('$key:');
      }
      continue;
    }

    if (line.isEmpty) continue;
    final currentIndent = line.length - line.trimLeft().length;
    if (currentIndent <= indent && line.trim().isNotEmpty) break;

    final trimmed = line.trim();
    final colon = trimmed.indexOf(':');
    if (colon == -1) continue;

    final childKey = trimmed.substring(0, colon).trim();
    final value = trimmed.substring(colon + 1).trim();
    result[childKey] = value.replaceAll("'", '').replaceAll('"', '');
  }

  return result;
}

Map<String, Map<String, String>> _typographyStyles(String yaml) {
  final lines = yaml.split('\n');
  final result = <String, Map<String, String>>{};
  var inTypography = false;
  var typographyIndent = 0;
  String? currentStyle;
  var styleIndent = 0;

  for (final line in lines) {
    if (!inTypography) {
      if (line.trim() == 'typography:') {
        inTypography = true;
        typographyIndent = line.indexOf('typography:');
      }
      continue;
    }

    if (line.isEmpty) continue;
    final currentIndent = line.length - line.trimLeft().length;
    if (currentIndent <= typographyIndent && line.trim().isNotEmpty) break;

    final trimmed = line.trim();
    final colon = trimmed.indexOf(':');
    if (colon == -1) continue;

    final key = trimmed.substring(0, colon).trim();
    final value = trimmed.substring(colon + 1).trim();

    if (value.isEmpty) {
      currentStyle = key;
      styleIndent = currentIndent;
      result[currentStyle] = {};
      continue;
    }

    if (currentStyle != null && currentIndent > styleIndent) {
      result[currentStyle]![key] = value.replaceAll("'", '').replaceAll('"', '');
    }
  }

  return result;
}

const _orderedColorKeys = [
  (key: 'surface', field: 'surface'),
  (key: 'surface-dim', field: 'surfaceDim'),
  (key: 'surface-bright', field: 'surfaceBright'),
  (key: 'surface-container-lowest', field: 'surfaceContainerLowest'),
  (key: 'surface-container-low', field: 'surfaceContainerLow'),
  (key: 'surface-container', field: 'surfaceContainer'),
  (key: 'surface-container-high', field: 'surfaceContainerHigh'),
  (key: 'surface-container-highest', field: 'surfaceContainerHighest'),
  (key: 'on-surface', field: 'onSurface'),
  (key: 'on-surface-variant', field: 'onSurfaceVariant'),
  (key: 'inverse-surface', field: 'inverseSurface'),
  (key: 'inverse-on-surface', field: 'inverseOnSurface'),
  (key: 'outline', field: 'outline'),
  (key: 'outline-variant', field: 'outlineVariant'),
  (key: 'surface-tint', field: 'surfaceTint'),
  (key: 'primary', field: 'primary'),
  (key: 'on-primary', field: 'onPrimary'),
  (key: 'primary-container', field: 'primaryContainer'),
  (key: 'on-primary-container', field: 'onPrimaryContainer'),
  (key: 'inverse-primary', field: 'inversePrimary'),
  (key: 'secondary', field: 'secondary'),
  (key: 'on-secondary', field: 'onSecondary'),
  (key: 'secondary-container', field: 'secondaryContainer'),
  (key: 'on-secondary-container', field: 'onSecondaryContainer'),
  (key: 'tertiary', field: 'tertiary'),
  (key: 'on-tertiary', field: 'onTertiary'),
  (key: 'tertiary-container', field: 'tertiaryContainer'),
  (key: 'on-tertiary-container', field: 'onTertiaryContainer'),
  (key: 'error', field: 'error'),
  (key: 'on-error', field: 'onError'),
  (key: 'error-container', field: 'errorContainer'),
  (key: 'on-error-container', field: 'onErrorContainer'),
  (key: 'primary-fixed', field: 'primaryFixed'),
  (key: 'primary-fixed-dim', field: 'primaryFixedDim'),
  (key: 'on-primary-fixed', field: 'onPrimaryFixed'),
  (key: 'on-primary-fixed-variant', field: 'onPrimaryFixedVariant'),
  (key: 'secondary-fixed', field: 'secondaryFixed'),
  (key: 'secondary-fixed-dim', field: 'secondaryFixedDim'),
  (key: 'on-secondary-fixed', field: 'onSecondaryFixed'),
  (key: 'on-secondary-fixed-variant', field: 'onSecondaryFixedVariant'),
  (key: 'tertiary-fixed', field: 'tertiaryFixed'),
  (key: 'tertiary-fixed-dim', field: 'tertiaryFixedDim'),
  (key: 'on-tertiary-fixed', field: 'onTertiaryFixed'),
  (key: 'on-tertiary-fixed-variant', field: 'onTertiaryFixedVariant'),
  (key: 'background', field: 'background'),
  (key: 'on-background', field: 'onBackground'),
  (key: 'surface-variant', field: 'surfaceVariant'),
];

String _colorLiteral(String hex) {
  var value = hex.trim();
  if (value.startsWith('#')) value = value.substring(1);
  if (value.length == 6) value = 'FF$value';
  return 'Color(0x${value.toUpperCase()})';
}

String _fontWeightLiteral(String value) {
  final weight = int.parse(value.replaceAll("'", '').trim());
  return 'FontWeight.w$weight';
}

String _remLiteral(String value) => _parseRem(value).toString();

double _parseRem(String value) {
  final trimmed = value.trim().replaceAll("'", '');
  if (trimmed.endsWith('rem')) {
    return double.parse(trimmed.replaceAll('rem', '').trim()) * 16;
  }
  if (trimmed.endsWith('px')) {
    return double.parse(trimmed.replaceAll('px', '').trim());
  }
  return double.parse(trimmed);
}

double _parsePx(String value) {
  final trimmed = value.trim().replaceAll("'", '');
  if (trimmed.endsWith('px')) {
    return double.parse(trimmed.replaceAll('px', '').trim());
  }
  return double.parse(trimmed);
}

double _parseEm(String value) {
  final trimmed = value.trim().replaceAll("'", '');
  if (trimmed.endsWith('em')) {
    return double.parse(trimmed.replaceAll('em', '').trim());
  }
  return double.parse(trimmed);
}

String _toSnakeCase(String input) {
  return input
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

String _toPascalCase(String snake) {
  return snake.split('_').map((p) => p.isEmpty ? '' : p[0].toUpperCase() + p.substring(1)).join();
}
