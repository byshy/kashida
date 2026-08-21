import 'package:flutter_test/flutter_test.dart';
import 'package:kashida/kashida.dart';
import 'package:kashida/src/unicode/joining.dart';

void main() {
  group('happy paths', () {
    test('empty pattern text compiles to an empty set', () {
      final set = compilePatternText('');
      expect(findKashidaPointsPatterns('بيت', set), isEmpty);
    });

    test('comment-only pattern text compiles to an empty set', () {
      final set = compilePatternText('# just a comment\n\n  # another\n');
      expect(findKashidaPointsPatterns('بيت', set), isEmpty);
    });

    test('wildcard pattern marks every connection', () {
      final set = compilePatternText('* 5 *');
      expect(
        findKashidaPointsPatterns('بيت', set).map((k) => (k.index, k.priority)),
        [(0, 5), (1, 5)],
      );
    });

    test('leading boundary only matches the start of a joined run', () {
      expect(compileAndPoints('مبسم', '. @Seen 8 *'), isEmpty);
      expect(compileAndPoints('سمب', '. @Seen 8 *'), [(0, 8)]);
    });

    test('CRLF line endings compile like LF', () {
      expect(compileAndPoints('بت', 'ب2ت\r\nب5ت'), [(0, 5)]);
    });

    test('tabs are valid pattern whitespace and use separators', () {
      expect(compileAndPoints('بت', 'ب\t2\tت'), [(0, 2)]);
      expect(compileAndPoints('بحه', 'use\tarabic-naskh'), [(1, 9)]);
    });

    test('later use still lets following rules override', () {
      expect(compileAndPoints('سبت', 'use arabic-simple\n{@Seen @Sad} ! *'), [
        (1, 3),
      ]);
    });

    test('builtin sets are cached and case-sensitive', () {
      final first = builtinPatternSet('arabic-naskh');
      final second = builtinPatternSet('arabic-naskh');
      expect(identical(first, second), isTrue);
      expect(isBuiltinPatternSet('Arabic-Naskh'), isFalse);
      expect(builtinPatternSet('Arabic-Naskh'), isNull);
      expect(isBuiltinPatternSet(''), isFalse);
    });

    test('exact range guard [3:3] is the same as [3]', () {
      expect(compileAndPoints('بتر', '[3:3]ب2ت'), [(0, 2)]);
      expect(compileAndPoints('بت', '[3:3]ب2ت'), isEmpty);
    });

    test('9\\9 is a constant priority', () {
      expect(compileAndPoints('بت', '[2:]ب9\\9ت'), [(0, 9)]);
      expect(compileAndPoints('بتننن', '[2:]ب9\\9ت'), [(0, 9)]);
    });
  });

  group('empty and non-joining input', () {
    test('empty and whitespace text have no points', () {
      final set = builtinPatternSet('arabic-naskh')!;
      final empty = findKashidaPoints('', set);
      expect(empty.text, isEmpty);
      expect(empty.points, isEmpty);
      expect(findKashidaPointsPatterns('   \n\t  ', set), isEmpty);
      expect(findKashidaPointsPatterns('Hello, world!', set), isEmpty);
      expect(findKashidaPointsPatterns('١٢٣', set), isEmpty);
    });

    test('a single joining letter has no connection', () {
      final set = compilePatternText('* 9 *');
      expect(findKashidaPointsPatterns('ب', set), isEmpty);
      expect(findKashidaPointsPatterns('ـ', set), isEmpty);
    });

    test('latin between arabic letters splits joined runs', () {
      final set = compilePatternText('ب2ت');
      expect(findKashidaPointsPatterns('بxت', set), isEmpty);
      expect(
        findKashidaPointsPatterns(
          'بت بت',
          set,
        ).map((k) => (k.index, k.priority)),
        [(0, 2), (3, 2)],
      );
    });

    test('punctuation is not a joining letter of the run', () {
      final set = builtinPatternSet('arabic-naskh')!;
      expect(findKashidaPointsPatterns('،', set), isEmpty);
      expect(findKashidaPointsPatterns('«»', set), isEmpty);
    });
  });

  group('stripping and indices', () {
    test('trailing and lone bare tatweels are stripped', () {
      final set = compilePatternText('ب2ت');
      expect(findKashidaPoints('ـ', set).text, '');
      expect(findKashidaPoints('بـ', set).text, 'ب');
      expect(findKashidaPoints('ـبت', set).text, 'بت');
      expect(findKashidaPoints('بــت', set).text, 'بت');
    });

    test('points refer to the cleaned string after stripping', () {
      final set = compilePatternText('ب2ت');
      final found = findKashidaPoints('بـت', set);
      expect(found.text, 'بت');
      expect(found.points, [const KashidaPoint(index: 0, priority: 2)]);
    });

    test('stripBareTatweel is a no-op when there is no tatweel', () {
      final set = compilePatternText('ب2ت');
      expect(findKashidaPoints('بت', set).text, 'بت');
      expect(
        findKashidaPoints('بت', set, removeExistingKashida: false).text,
        'بت',
      );
    });
  });

  group('compile errors', () {
    test('line numbers are 1-based and skip blanks', () {
      expect(
        compileError('# comment\n\n@Nope 2 ت'),
        isA<CompileError>()
            .having((e) => e.lineNumber, 'lineNumber', 3)
            .having((e) => e.kind, 'kind', isA<UnknownGroupName>()),
      );
      expect(
        compileError('# comment\n\n@Nope 2 ت').toString(),
        startsWith('line 3: '),
      );
    });

    test('unknown import reports the set name', () {
      final error = compileError('use missing-set');
      expect(error.kind, isA<UnknownImport>());
      expect(error.toString(), contains('missing-set'));
    });

    test('Hamza_On_Heh_Goal alias is not a long name', () {
      expect(
        compileError('@Hamza_On_Heh_Goal 2 ت').kind,
        isA<UnknownGroupName>(),
      );
    });

    test('a pattern longer than the run simply does not match', () {
      expect(compileAndPoints('بت', 'ب2ت2ن'), isEmpty);
    });
  });

  group('KashidaPoint', () {
    test('equality hashCode and toString', () {
      const a = KashidaPoint(index: 1, priority: 9);
      const b = KashidaPoint(index: 1, priority: 9);
      const c = KashidaPoint(index: 2, priority: 9);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
      expect(a.toString(), 'KashidaPoint(index: 1, priority: 9)');
    });
  });

  group('unicode joining lookups', () {
    test('known codepoints have the expected joining type', () {
      expect(joiningTypeOf(0x0628), JoiningType.dualJoining); // beh
      expect(joiningTypeOf(0x0627), JoiningType.rightJoining); // alef
      expect(joiningTypeOf(kashidaCodepoint), JoiningType.joinCausing);
      expect(joiningTypeOf(0x200C), JoiningType.nonJoining); // ZWNJ
      expect(joiningTypeOf(0x200D), JoiningType.joinCausing); // ZWJ
      expect(joiningTypeOf(0x064E), JoiningType.transparent); // fatha
      expect(joiningTypeOf(0x0041), JoiningType.nonJoining); // A
    });
  });
}

List<(int, int)> compileAndPoints(String word, String pattern) {
  final set = compilePatternText(pattern);
  return findKashidaPointsPatterns(
    word,
    set,
  ).map((k) => (k.index, k.priority)).toList();
}

CompileError compileError(String pattern) {
  try {
    compilePatternText(pattern);
    fail('pattern should fail to compile');
  } on CompileError catch (e) {
    return e;
  }
}
