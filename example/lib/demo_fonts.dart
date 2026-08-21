import 'package:flutter/painting.dart';
import 'package:google_fonts/google_fonts.dart';

/// A face the example can measure and paint with.
///
/// Layout uses the [TextStyle] from [styleAt], so kashida fill tracks this
/// font's metrics. Pattern sets stay independent: pick the rules that match
/// the writing style of the face.
class DemoFont {
  DemoFont({
    required this.id,
    required this.label,
    required this.suggestedPattern,
    required TextStyle Function(double fontSize) style,
  }) : _style = style;

  final String id;
  final String label;

  /// Built-in pattern set that usually fits this writing style.
  final String suggestedPattern;

  final TextStyle Function(double fontSize) _style;

  TextStyle styleAt(double fontSize) => _style(fontSize);
}

final demoFonts = <DemoFont>[
  DemoFont(
    id: 'noto-naskh',
    label: 'Noto Naskh Arabic',
    suggestedPattern: 'arabic-naskh',
    style: (size) => GoogleFonts.notoNaskhArabic(fontSize: size, height: 1.5),
  ),
  DemoFont(
    id: 'amiri',
    label: 'Amiri',
    suggestedPattern: 'arabic-naskh',
    style: (size) => GoogleFonts.amiri(fontSize: size, height: 1.5),
  ),
  DemoFont(
    id: 'scheherazade',
    label: 'Scheherazade New',
    suggestedPattern: 'arabic-naskh',
    style: (size) => GoogleFonts.scheherazadeNew(fontSize: size, height: 1.5),
  ),
  DemoFont(
    id: 'lateef',
    label: 'Lateef',
    suggestedPattern: 'arabic-naskh',
    style: (size) => GoogleFonts.lateef(fontSize: size, height: 1.5),
  ),
  DemoFont(
    id: 'noto-sans-arabic',
    label: 'Noto Sans Arabic',
    suggestedPattern: 'arabic-simple',
    style: (size) => GoogleFonts.notoSansArabic(fontSize: size, height: 1.5),
  ),
  DemoFont(
    id: 'noto-kufi',
    label: 'Noto Kufi Arabic',
    suggestedPattern: 'arabic-simple',
    style: (size) => GoogleFonts.notoKufiArabic(fontSize: size, height: 1.5),
  ),
  DemoFont(
    id: 'noto-nastaliq',
    label: 'Noto Nastaliq Urdu',
    suggestedPattern: 'arabic-nastaliq',
    style: (size) => GoogleFonts.notoNastaliqUrdu(fontSize: size, height: 1.5),
  ),
  DemoFont(
    id: 'noto-sans-syriac',
    label: 'Noto Sans Syriac',
    suggestedPattern: 'syriac',
    style: (size) => GoogleFonts.notoSansSyriac(fontSize: size, height: 1.5),
  ),
];

DemoFont demoFontById(String id) =>
    demoFonts.firstWhere((font) => font.id == id, orElse: () => demoFonts.first);
