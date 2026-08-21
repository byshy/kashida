import 'package:flutter/painting.dart';

/// A face the example measures and paints with.
///
/// These files live in `fonts/` and are declared in `pubspec.yaml`, so the
/// same glyphs load on macOS, iOS, Android, and web without a network fetch.
class DemoFont {
  DemoFont({
    required this.id,
    required this.label,
    required this.family,
    required this.suggestedPattern,
  });

  final String id;
  final String label;
  final String family;

  /// Built-in pattern set that usually fits this writing style.
  final String suggestedPattern;

  TextStyle styleAt(double fontSize) =>
      TextStyle(fontFamily: family, fontSize: fontSize, height: 1.5);
}

final demoFonts = <DemoFont>[
  DemoFont(
    id: 'noto-naskh',
    label: 'Noto Naskh Arabic',
    family: 'Noto Naskh Arabic',
    suggestedPattern: 'arabic-naskh',
  ),
  DemoFont(
    id: 'amiri',
    label: 'Amiri',
    family: 'Amiri',
    suggestedPattern: 'arabic-naskh',
  ),
  DemoFont(
    id: 'scheherazade',
    label: 'Scheherazade New',
    family: 'Scheherazade New',
    suggestedPattern: 'arabic-naskh',
  ),
  DemoFont(
    id: 'lateef',
    label: 'Lateef',
    family: 'Lateef',
    suggestedPattern: 'arabic-naskh',
  ),
  DemoFont(
    id: 'noto-sans-arabic',
    label: 'Noto Sans Arabic',
    family: 'Noto Sans Arabic',
    suggestedPattern: 'arabic-simple',
  ),
  DemoFont(
    id: 'noto-kufi',
    label: 'Noto Kufi Arabic',
    family: 'Noto Kufi Arabic',
    suggestedPattern: 'arabic-simple',
  ),
  DemoFont(
    id: 'noto-nastaliq',
    label: 'Noto Nastaliq Urdu',
    family: 'Noto Nastaliq Urdu',
    suggestedPattern: 'arabic-nastaliq',
  ),
  DemoFont(
    id: 'noto-sans-syriac',
    label: 'Noto Sans Syriac',
    family: 'Noto Sans Syriac',
    suggestedPattern: 'syriac',
  ),
];

DemoFont demoFontById(String id) => demoFonts.firstWhere(
  (font) => font.id == id,
  orElse: () => demoFonts.first,
);
