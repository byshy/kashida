import 'package:flutter/painting.dart';

import 'layout.dart';
import 'pattern.dart';

/// Pixel width of [text] in [style], using Flutter's text layout.
double measureTextWidth(
  String text,
  TextStyle style, {
  TextScaler textScaler = TextScaler.noScaling,
  TextDirection textDirection = TextDirection.rtl,
}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: textDirection,
    textScaler: textScaler,
    maxLines: 1,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

/// [layoutParagraph] measured with [style] (typically your on-screen font).
List<KashidaLine> layoutParagraphStyled(
  String text,
  PatternSet set,
  TextStyle style, {
  required double width,
  TextScaler textScaler = TextScaler.noScaling,
  TextDirection textDirection = TextDirection.rtl,
  int minKashidas = 1,
  int maxKashidas = 4,
  bool justified = true,
  bool justifyLastLine = false,
  bool applyKashida = true,
  bool removeExistingKashida = true,
  KashidaFillStyle? fill,
}) {
  return layoutParagraph(
    text,
    set,
    width: width,
    measure: (value) => measureTextWidth(
      value,
      style,
      textScaler: textScaler,
      textDirection: textDirection,
    ),
    minKashidas: minKashidas,
    maxKashidas: maxKashidas,
    justified: justified,
    justifyLastLine: justifyLastLine,
    applyKashida: applyKashida,
    removeExistingKashida: removeExistingKashida,
    fill: fill,
  );
}
