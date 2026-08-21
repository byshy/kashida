import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kashida/kashida.dart';
import 'package:kashida_example/justify.dart';

void main() {
  const style = TextStyle(fontSize: 20, height: 1.5);

  test('clampParagraphWidth reflows to the window instead of overflowing', () {
    expect(clampParagraphWidth(680, 400), 400);
    expect(clampParagraphWidth(400, 800), 400);
    expect(clampParagraphWidth(680, double.infinity), 680);
  });

  test('narrower width wraps onto more lines', () {
    final set = builtinPatternSet('arabic-naskh')!;
    final wide = layoutParagraph(sampleText, set, style, width: 680);
    final narrow = layoutParagraph(sampleText, set, style, width: 320);
    expect(narrow.length, greaterThan(wide.length));
  });

  test('justified lines stretch except the last', () {
    final set = builtinPatternSet('arabic-naskh')!;
    final lines = layoutParagraph(sampleText, set, style, width: 400);
    expect(lines.length, greaterThan(1));
    expect(lines.last.stretch, isFalse);
    expect(lines.take(lines.length - 1).every((line) => line.stretch), isTrue);
  });
}
