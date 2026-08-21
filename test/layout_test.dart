import 'package:characters/characters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kashida/kashida.dart';

double _ems(String text) => text.characters.length.toDouble();

const _sample = 'قال أفلاطون الخط عقال العقل وقال إقليدس الخط هندسة روحانية';

void main() {
  final naskh = requiredBuiltinPatternSet('arabic-naskh');

  test('empty and whitespace produce no lines', () {
    expect(layoutParagraph('', naskh, width: 20, measure: _ems), isEmpty);
    expect(
      layoutParagraph('   \n\t ', naskh, width: 20, measure: _ems),
      isEmpty,
    );
  });

  test('a single word is one unstretched line', () {
    final lines = layoutParagraph(
      'المستشفيات',
      naskh,
      width: 40,
      measure: _ems,
    );
    expect(lines, hasLength(1));
    expect(lines.single.stretch, isFalse);
    expect(lines.single.words.single.text, 'المستشفيات');
  });

  test('narrower width wraps onto more lines', () {
    final wide = layoutParagraph(_sample, naskh, width: 40, measure: _ems);
    final narrow = layoutParagraph(_sample, naskh, width: 8, measure: _ems);
    expect(narrow.length, greaterThan(wide.length));
  });

  test('justified lines stretch except the last', () {
    final lines = layoutParagraph(_sample, naskh, width: 16, measure: _ems);
    expect(lines.length, greaterThan(1));
    expect(lines.last.stretch, isFalse);
    expect(lines.take(lines.length - 1).every((line) => line.stretch), isTrue);
  });

  test('applyKashida false still wraps but inserts no tatweel', () {
    final lines = layoutParagraph(
      _sample,
      naskh,
      width: 16,
      measure: _ems,
      applyKashida: false,
    );
    expect(lines.length, greaterThan(1));
    expect(lines.every((line) => !line.text.contains(kashida)), isTrue);
  });

  test('layout keeps every word of the source text', () {
    final lines = layoutParagraph(_sample, naskh, width: 10, measure: _ems);
    final laidOut = lines
        .expand((line) => line.words.map((word) => word.text))
        .join(' ');
    expect(laidOut, _sample);
  });

  test('unjustified layout never stretches', () {
    final lines = layoutParagraph(
      _sample,
      naskh,
      width: 16,
      measure: _ems,
      justified: false,
    );
    expect(lines.every((line) => line.stretch == false), isTrue);
  });

  test('typed tatweel is stripped from words by default', () {
    final simple = requiredBuiltinPatternSet('arabic-simple');
    final stripped = layoutParagraph(
      'بـت بيت',
      simple,
      width: 40,
      measure: _ems,
    );
    expect(stripped.single.words.map((w) => w.text).toList(), ['بت', 'بيت']);
    final kept = layoutParagraph(
      'بـت بيت',
      simple,
      width: 40,
      measure: _ems,
      removeExistingKashida: false,
    );
    expect(kept.single.words.first.text, 'بـت');
  });

  test('syriac fill is inferred from the builtin set id', () {
    final lines = layoutParagraph(
      _sample,
      requiredBuiltinPatternSet('syriac'),
      width: 16,
      measure: _ems,
    );
    expect(lines, isNotEmpty);
    expect(lines.last.stretch, isFalse);
  });

  test('newlines start a new paragraph', () {
    final lines = layoutParagraph(
      'المستشفيات\nبيت بيت بيت',
      naskh,
      width: 80,
      measure: _ems,
    );
    expect(lines.first.words.single.text, 'المستشفيات');
    expect(lines.first.stretch, isFalse);
    expect(lines.length, greaterThan(1));
    expect(lines.expand((line) => line.words.map((w) => w.text)).toList(), [
      'المستشفيات',
      'بيت',
      'بيت',
      'بيت',
    ]);
  });

  test('unusedWidth is leftover after fill', () {
    final lines = layoutParagraph(_sample, naskh, width: 16, measure: _ems);
    final stretched = lines.firstWhere((line) => line.stretch);
    expect(stretched.unusedWidth(16, _ems), greaterThanOrEqualTo(0));
    expect(stretched.unusedWidth(16, _ems), lessThan(16));
  });

  test('a larger measure wraps more', () {
    final compact = layoutParagraph(
      _sample,
      naskh,
      width: 80,
      measure: (text) => text.characters.length.toDouble(),
    );
    final wideGlyphs = layoutParagraph(
      _sample,
      naskh,
      width: 80,
      measure: (text) => text.characters.length * 8.0,
    );
    expect(wideGlyphs.length, greaterThan(compact.length));
  });
}
