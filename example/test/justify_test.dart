import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kashida/kashida.dart' hide layoutParagraph;
import 'package:kashida_example/demo_fonts.dart';
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

  test('empty and whitespace produce no lines', () {
    final set = builtinPatternSet('arabic-naskh')!;
    expect(layoutParagraph('', set, style, width: 400), isEmpty);
    expect(layoutParagraph('   \n\t ', set, style, width: 400), isEmpty);
  });

  test('a single word is one unstretched line', () {
    final set = builtinPatternSet('arabic-naskh')!;
    final lines = layoutParagraph('المستشفيات', set, style, width: 400);
    expect(lines, hasLength(1));
    expect(lines.single.stretch, isFalse);
    expect(lines.single.words.single.text, 'المستشفيات');
  });

  test('unjustified layout never stretches', () {
    final set = builtinPatternSet('arabic-naskh')!;
    final lines = layoutParagraph(
      sampleText,
      set,
      style,
      width: 400,
      justified: false,
    );
    expect(lines, isNotEmpty);
    expect(lines.every((line) => line.stretch == false), isTrue);
  });

  test('applyKashida false still wraps but inserts no tatweel', () {
    final set = builtinPatternSet('arabic-naskh')!;
    final lines = layoutParagraph(
      sampleText,
      set,
      style,
      width: 400,
      applyKashida: false,
    );
    expect(lines.length, greaterThan(1));
    expect(lines.take(lines.length - 1).every((line) => line.stretch), isTrue);
    expect(lines.every((line) => !line.text.contains('\u{0640}')), isTrue);
  });

  test('layout keeps every word of the source text', () {
    final set = builtinPatternSet('arabic-naskh')!;
    final lines = layoutParagraph(sampleText, set, style, width: 280);
    final laidOut = lines
        .expand((line) => line.words.map((word) => word.text))
        .join(' ');
    final source = sampleText
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .join(' ');
    expect(laidOut, source);
  });

  test('very narrow width puts at most one word on most lines', () {
    final set = builtinPatternSet('arabic-naskh')!;
    final lines = layoutParagraph(sampleText, set, style, width: 12);
    expect(lines.length, greaterThan(8));
    expect(lines.every((line) => line.words.length <= 2), isTrue);
  });

  test('syriac layout does not throw on the sample text', () {
    final set = builtinPatternSet('syriac')!;
    final lines = layoutParagraph(
      sampleText,
      set,
      style,
      width: 400,
      syriac: true,
    );
    expect(lines, isNotEmpty);
    expect(lines.last.stretch, isFalse);
  });

  test('typed tatweel is stripped from words by default', () {
    final set = builtinPatternSet('arabic-simple')!;
    final stripped = layoutParagraph('بـت بيت', set, style, width: 400);
    expect(stripped.single.words.map((w) => w.text).toList(), ['بت', 'بيت']);
    final kept = layoutParagraph(
      'بـت بيت',
      set,
      style,
      width: 400,
      removeExistingKashida: false,
    );
    expect(kept.single.words.first.text, 'بـت');
  });

  test('clampParagraphWidth keeps the request when available is unusable', () {
    expect(clampParagraphWidth(680, 0), 680);
    expect(clampParagraphWidth(680, -20), 680);
    expect(clampParagraphWidth(680, double.nan), 680);
  });

  test('layout measures with the given TextStyle', () {
    final set = builtinPatternSet('arabic-naskh')!;
    const compact = TextStyle(fontSize: 12, height: 1.5);
    const large = TextStyle(fontSize: 48, height: 1.5);
    final few = layoutParagraph(sampleText, set, compact, width: 400);
    final many = layoutParagraph(sampleText, set, large, width: 400);
    expect(many.length, greaterThan(few.length));
    expect(
      measureWidth(sampleText, large),
      greaterThan(measureWidth(sampleText, compact)),
    );
  });

  test('a different fontFamily still lays out without throwing', () {
    final set = builtinPatternSet('arabic-naskh')!;
    const custom = TextStyle(
      fontFamily: 'DemoCustomFace',
      fontSize: 20,
      height: 1.5,
    );
    final lines = layoutParagraph(sampleText, set, custom, width: 400);
    expect(lines, isNotEmpty);
    expect(lines.last.stretch, isFalse);
  });

  test('demo fonts suggest existing builtin pattern sets', () {
    expect(demoFonts, isNotEmpty);
    for (final font in demoFonts) {
      expect(isBuiltinPatternSet(font.suggestedPattern), isTrue);
    }
    expect(demoFontById('missing').id, demoFonts.first.id);
  });
}
