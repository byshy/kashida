import 'package:flutter/painting.dart';
import 'package:kashida/kashida.dart' as kashida;

export 'package:kashida/kashida.dart'
    show KashidaLine, KashidaWord, KashidaFillStyle;

/// Uses [requested] unless the window is narrower, so layout can reflow
/// instead of overflowing.
double clampParagraphWidth(double requested, double available) {
  if (available.isInfinite || available.isNaN || available <= 0) {
    return requested;
  }
  return requested < available ? requested : available;
}

const sampleText =
    'قال أفلاطون: «الخط عقال العقل». وقال إقليدس '
    'الإغريقي: «الخط هندسة روحانية وإن ظهرت بآلة '
    'جسمانية». وقال أبو دلف رحالة القرن العاشر '
    'الميلادي: «الخط رياض العلوم». وقال النظام المعتزلي: '
    '«الخط أصيل في الروح وإن ظهر بحواس البدن».';

double measureWidth(
  String text,
  TextStyle style, {
  TextScaler textScaler = TextScaler.noScaling,
}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.rtl,
    textScaler: textScaler,
    maxLines: 1,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

/// Wraps and justifies using [style] for measurement and painting.
List<kashida.KashidaLine> layoutParagraph(
  String text,
  kashida.PatternSet set,
  TextStyle style, {
  required double width,
  TextScaler textScaler = TextScaler.noScaling,
  int minKashidas = 2,
  int maxKashidas = 4,
  bool justified = true,
  bool applyKashida = true,
  bool removeExistingKashida = true,
  bool syriac = false,
}) {
  return kashida.layoutParagraph(
    text,
    set,
    width: width,
    measure: (value) => measureWidth(value, style, textScaler: textScaler),
    minKashidas: minKashidas,
    maxKashidas: maxKashidas,
    justified: justified,
    applyKashida: applyKashida,
    removeExistingKashida: removeExistingKashida,
    fill: syriac
        ? kashida.KashidaFillStyle.syriac
        : kashida.KashidaFillStyle.arabic,
  );
}
