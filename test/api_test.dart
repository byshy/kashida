import 'package:characters/characters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kashida/kashida.dart';

void main() {
  group('insertKashida', () {
    test('returns the elongated string', () {
      final set = compilePatternText('ب2ت');
      expect(insertKashida('بت', set), 'بـت');
      expect(insertKashida('بت', set, count: 2), 'بــت');
    });

    test('skips points below minPriority', () {
      final set = compilePatternText('ب2ت');
      expect(insertKashida('بت', set, minPriority: 3), 'بت');
      expect(insertKashida('بت', set, minPriority: 2), 'بـت');
    });

    test('count zero leaves the text unchanged', () {
      final set = compilePatternText('ب2ت');
      expect(insertKashida('بت', set, count: 0), 'بت');
    });

    test('strips bare tatweel before inserting', () {
      final set = compilePatternText('ب2ت');
      expect(insertKashida('بـت', set), 'بـت');
      expect(
        insertKashida('بـت', set, removeExistingKashida: false, count: 0),
        'بـت',
      );
    });
  });

  group('insertKashidaAt', () {
    test('inserts from the end so earlier indices stay valid', () {
      final out = insertKashidaAt('بيت', const [
        KashidaPoint(index: 0, priority: 1),
        KashidaPoint(index: 1, priority: 9),
      ]);
      expect(out, 'بـيـت');
    });

    test('rejects a negative count', () {
      expect(
        () => insertKashidaAt('بت', const [
          KashidaPoint(index: 0, priority: 1),
        ], count: -1),
        throwsArgumentError,
      );
    });

    test('rejects an out-of-range grapheme index', () {
      expect(
        () => insertKashidaAt('ب', const [KashidaPoint(index: 1, priority: 1)]),
        throwsRangeError,
      );
    });
  });

  group('KashidaAnalysis', () {
    test('insert uses the cleaned text', () {
      final set = compilePatternText('ب2ت');
      final found = findKashidaPoints('بـت', set);
      expect(found.text, 'بت');
      expect(found.insert(), 'بـت');
      expect(
        found,
        KashidaAnalysis(
          text: 'بت',
          points: const [KashidaPoint(index: 0, priority: 2)],
        ),
      );
    });
  });

  group('requiredBuiltinPatternSet', () {
    test('returns a cached builtin set', () {
      final a = requiredBuiltinPatternSet('arabic-simple');
      final b = builtinPatternSet('arabic-simple');
      expect(identical(a, b), isTrue);
      expect(a.patterns, isNotEmpty);
    });

    test('throws on an unknown name', () {
      expect(
        () => requiredBuiltinPatternSet('nope'),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Unknown built-in pattern set'),
          ),
        ),
      );
    });
  });

  test('kashida constants are U+0640', () {
    expect(kashida, '\u{0640}');
    expect(kashidaCodepoint, 0x0640);
    expect(kashida.characters.single, kashida);
  });
}
