import 'package:flutter/widgets.dart';

import 'flutter_measure.dart';
import 'layout.dart';
import 'pattern.dart';

/// Justified Arabic/Syriac paragraph using [patternSet] and [style].
///
/// Stretched lines put leftover pixels between words (`spaceBetween`).
/// Newlines start a new paragraph. The last line of each is stretched only
/// when [justifyLastLine] is true.
class KashidaText extends StatelessWidget {
  /// Creates a kashida-justified text block of [width] logical pixels.
  const KashidaText(
    this.text, {
    super.key,
    required this.patternSet,
    required this.width,
    this.style,
    this.textScaler,
    this.textDirection = TextDirection.rtl,
    this.minKashidas = 1,
    this.maxKashidas = 4,
    this.justified = true,
    this.justifyLastLine = false,
    this.applyKashida = true,
    this.removeExistingKashida = true,
    this.fill,
  });

  /// Source paragraph(s).
  final String text;

  /// Rules used to pick insertion points.
  final PatternSet patternSet;

  /// Line width in logical pixels.
  final double width;

  /// Font and size used to measure and paint.
  final TextStyle? style;

  /// Inherited scaler if omitted.
  final TextScaler? textScaler;

  /// Always RTL for Arabic/Syriac kashida.
  final TextDirection textDirection;

  /// First tatweel batch per chosen point when filling.
  final int minKashidas;

  /// Cap on tatweels at one point.
  final int maxKashidas;

  /// Whether non-final lines of a paragraph should stretch.
  final bool justified;

  /// Whether the last line of each paragraph should also stretch to [width].
  final bool justifyLastLine;

  /// Whether stretching may insert tatweel.
  final bool applyKashida;

  /// Whether to strip bare tatweel before matching.
  final bool removeExistingKashida;

  /// Override [fillStyleFor] when the set has no builtin [PatternSet.id].
  final KashidaFillStyle? fill;

  @override
  Widget build(BuildContext context) {
    final resolvedStyle = style ?? DefaultTextStyle.of(context).style;
    final scaler =
        textScaler ??
        MediaQuery.maybeTextScalerOf(context) ??
        TextScaler.noScaling;
    final lines = layoutParagraphStyled(
      text,
      patternSet,
      resolvedStyle,
      width: width,
      textScaler: scaler,
      textDirection: textDirection,
      minKashidas: minKashidas,
      maxKashidas: maxKashidas,
      justified: justified,
      justifyLastLine: justifyLastLine,
      applyKashida: applyKashida,
      removeExistingKashida: removeExistingKashida,
      fill: fill,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final line in lines)
          _KashidaLineView(
            line: line,
            style: resolvedStyle,
            textDirection: textDirection,
          ),
      ],
    );
  }
}

class _KashidaLineView extends StatelessWidget {
  const _KashidaLineView({
    required this.line,
    required this.style,
    required this.textDirection,
  });

  final KashidaLine line;
  final TextStyle style;
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    if (!line.stretch || line.words.length < 2) {
      return Text(
        line.text,
        textDirection: textDirection,
        textAlign: TextAlign.start,
        softWrap: false,
        maxLines: 1,
        style: style,
      );
    }
    return Row(
      textDirection: textDirection,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final word in line.words)
          Text(
            word.elongated(),
            textDirection: textDirection,
            softWrap: false,
            maxLines: 1,
            style: style,
          ),
      ],
    );
  }
}
