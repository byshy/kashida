import 'package:flutter_test/flutter_test.dart';
import 'package:kashida/kashida.dart';
import 'package:kashida/src/grapheme.dart';
import 'package:kashida/src/rasm.dart';
import 'package:kashida/src/unicode/joining.dart';

List<(int, int)> points(String word, String text) {
  final set = compilePatternText(text);
  return findKashidaPointsPatterns(word, set)
      .map((k) => (k.index, k.priority))
      .toList();
}

List<(int, int)> builtinPoints(String name, String word) {
  final set = builtinPatternSet(name)!;
  return findKashidaPointsPatterns(word, set)
      .map((k) => (k.index, k.priority))
      .toList();
}

String errMsg(String text) {
  try {
    compilePatternText(text);
    fail('pattern should fail to compile');
  } on CompileError catch (e) {
    return e.toString();
  }
}

void main() {
  test('resolve group name matches long names only', () {
    expect(resolveGroupName('@Beh'), JoiningGroup.beh);
    expect(resolveGroupName('@Teh_Marbuta'), JoiningGroup.tehMarbuta);
    expect(resolveGroupName('@Farsi_Yeh'), JoiningGroup.farsiYeh);

    expect(() => resolveGroupName('Beh'), throwsA(isA<UnknownGroupName>()));
    expect(
      () => resolveGroupName('@TehMarbuta'),
      throwsA(isA<UnknownGroupName>()),
    );
    expect(
      () => resolveGroupName('@teh_marbuta'),
      throwsA(isA<UnknownGroupName>()),
    );
    expect(() => resolveGroupName('@beh'), throwsA(isA<UnknownGroupName>()));
    expect(() => resolveGroupName('@Nope'), throwsA(isA<UnknownGroupName>()));
    expect(
      () => resolveGroupName('@No_Joining_Group'),
      throwsA(isA<UnknownGroupName>()),
    );
  });

  test('form of derives positional form', () {
    final g = splitGraphemes('بنت');
    expect(formOf(g, 0), JoiningForm.initial);
    expect(formOf(g, 1), JoiningForm.medial);
    expect(formOf(g, 2), JoiningForm.finalForm);
    expect(formOf(splitGraphemes('ب'), 0), JoiningForm.isolated);
  });

  test('joins left tests', () {
    const cases = <(String, int, bool)>[
      ('بيت', 2, false),
      ('Test', 0, false),
      ('aب', 0, false),
      ('بa', 0, false),
      ('بaب', 0, false),
      ('نص', 0, true),
      ('نَص', 0, true),
      ('نَّص', 0, true),
      ('أب', 0, false),
      ('أَب', 0, false),
    ];
    for (final (word, index, expected) in cases) {
      expect(
        joinsLeft(splitGraphemes(word), index),
        expected,
        reason: '$word @ $index',
      );
    }
  });

  test('joins right tests', () {
    const cases = <(String, int, bool)>[
      ('بيت', 0, false),
      ('بيت', 2, true),
      ('Test', 0, false),
      ('بa', 1, false),
      ('معطار', 3, true),
      ('معطَار', 3, true),
      ('معطَّار', 3, true),
      ('ار', 1, false),
      ('اَر', 1, false),
    ];
    for (final (word, index, expected) in cases) {
      expect(
        joinsRight(splitGraphemes(word), index),
        expected,
        reason: '$word @ $index',
      );
    }
  });

  test('rasm folding', () {
    expect(
      rasmMatches(JoiningGroup.beh, JoiningGroup.noon, JoiningForm.medial),
      isTrue,
    );
    expect(
      rasmMatches(JoiningGroup.beh, JoiningGroup.yeh, JoiningForm.initial),
      isTrue,
    );
    expect(
      rasmMatches(JoiningGroup.beh, JoiningGroup.noon, JoiningForm.finalForm),
      isFalse,
    );
    expect(
      rasmMatches(JoiningGroup.beh, JoiningGroup.yeh, JoiningForm.isolated),
      isFalse,
    );
    expect(
      rasmMatches(JoiningGroup.beh, JoiningGroup.beh, JoiningForm.finalForm),
      isTrue,
    );
    expect(
      rasmMatches(JoiningGroup.feh, JoiningGroup.qaf, JoiningForm.medial),
      isTrue,
    );
    expect(
      rasmMatches(JoiningGroup.feh, JoiningGroup.qaf, JoiningForm.finalForm),
      isFalse,
    );
    expect(
      rasmMatches(JoiningGroup.noon, JoiningGroup.beh, JoiningForm.medial),
      isFalse,
    );
    expect(
      rasmMatches(JoiningGroup.noon, JoiningGroup.noon, JoiningForm.medial),
      isFalse,
    );
    expect(
      rasmMatches(JoiningGroup.noon, JoiningGroup.nya, JoiningForm.finalForm),
      isTrue,
    );
    expect(
      rasmMatches(JoiningGroup.qaf, JoiningGroup.feh, JoiningForm.medial),
      isFalse,
    );
  });

  test('letters match only themselves', () {
    expect(points('بت', 'ب2ت'), [(0, 2)]);
    expect(points('نت', 'ب2ت'), isEmpty);
    expect(points('نت', 'ٮ2ت'), isEmpty);
  });

  test('the last rule wins at a connection', () {
    expect(points('بت', 'ب2ت\nب5ت'), [(0, 5)]);
    expect(points('بت', 'ب5ت\nب2ت'), [(0, 2)]);
  });

  test('absent digit is no candidate explicit zero is weakest', () {
    expect(points('بت', 'بت'), isEmpty);
    expect(points('بت', 'ب0ت'), [(0, 0)]);
  });

  test('a suppression holds until a later rule speaks', () {
    expect(points('بت', 'ب9ت\nب!ت'), isEmpty);
    expect(points('بت', 'ب!ت\nب9ت'), [(0, 9)]);
  });

  test('length guards gate on joined run length', () {
    expect(points('بتر', '[3]ب2ت'), [(0, 2)]);
    expect(points('بتر', '[4]ب2ت'), isEmpty);
    expect(points('بتر', '[2:3]ب2ت'), [(0, 2)]);
    expect(points('بتبت', '[2:3]ب2ت'), isEmpty);
    expect(points('بت', '[2:]ب2ت'), [(0, 2)]);
    expect(points('بت', '[3:]ب2ت'), isEmpty);
  });

  test('priority steps down as run grows', () {
    List<(int, int)> steps(String word) => points(word, '[4:]ب6\\3ت');
    expect(steps('بتنن'), [(0, 6)]);
    expect(steps('بتننن'), [(0, 5)]);
    expect(steps('بتنننن'), [(0, 4)]);
    expect(steps('بتننننن'), [(0, 3)]);
    expect(steps('بتنننننن'), [(0, 3)]);
  });

  test('an open guard matches any length and drops off either way', () {
    List<(int, int)> steps(String word) => points(word, '[:4:]ب6\\3ت');
    expect(steps('بت'), [(0, 4)]);
    expect(steps('بتن'), [(0, 5)]);
    expect(steps('بتنن'), [(0, 6)]);
    expect(steps('بتننن'), [(0, 5)]);
    expect(steps('بتنننن'), [(0, 4)]);
    expect(steps('بتننننن'), [(0, 3)]);
    expect(steps('بتنننننن'), [(0, 3)]);
  });

  test('an open guard clamps a short run at the second digit', () {
    expect(points('بت', '[:6:]ب3\\2ت'), [(0, 2)]);
    expect(points('بت', '[:4:]ب6ت'), [(0, 6)]);
    expect(points('بتنن', '[:4:]ب6ت'), [(0, 6)]);
  });

  test('an open guard bound is still checked', () {
    expect(errMsg('[:1:]ب2ت'), contains('Invalid length guard'));
    expect(errMsg('[:x:]ب2ت'), contains('Invalid length guard'));
    expect(errMsg('[:4]ب2ت'), contains('Invalid length guard'));
  });

  test('lam alef is suppressed by the pattern sets', () {
    expect(points('لا', '2ا'), [(0, 2)]);
    expect(points('با', '2ا'), [(0, 2)]);
    expect(builtinPoints('arabic-simple', 'لا'), isEmpty);
    expect(builtinPoints('arabic-naskh', 'لا'), isEmpty);
    expect(builtinPoints('arabic-simple', 'لب'), [(0, 3)]);
  });

  test('inline group set matches any of its groups', () {
    const set = '{@Beh @Noon @Yeh} 5 ت';
    expect(points('بت', set), [(0, 5)]);
    expect(points('نت', set), [(0, 5)]);
    expect(points('صت', set), isEmpty);
  });

  test('group sets accept literals and tatweel', () {
    const set = '{=Seen ب} 5 ت';
    expect(points('ست', set), [(0, 5)]);
    expect(points('بت', set), [(0, 5)]);
    expect(points('نت', set), isEmpty);
    expect(points('بـت', '{@Tatweel} 9'), [(1, 9)]);
  });

  test('set members behave as they do outside', () {
    expect(points('نت', '@Beh 5 ت'), points('نت', '{@Beh} 5 ت'));
    expect(points('نت', '{@Beh} 5 ت'), [(0, 5)]);
  });

  test('exact group reference does not fold', () {
    expect(points('بت', '=Beh 5 ت'), [(0, 5)]);
    expect(points('نت', '=Beh 5 ت'), isEmpty);
    expect(points('نت', '{=Beh} 5 ت'), isEmpty);
    expect(points('نت', '^=Beh 5 ت'), [(0, 5)]);
    expect(errMsg('=Foo 5 ت'), contains('Unknown'));
    expect(points('بـت', '=Tatweel 9'), points('بـت', '@Tatweel 9'));
  });

  test('group in no rasm class matches itself alone', () {
    expect(points('ست', '@Seen 5 *'), [(0, 5)]);
    expect(points('ست', '=Seen 5 *'), [(0, 5)]);
  });

  test('not group set matches any joining letter not in set', () {
    const set = '^{@Beh @Noon} 5 ت';
    expect(points('صت', set), [(0, 5)]);
    expect(points('بت', set), isEmpty);
    expect(points('نت', set), isEmpty);
    expect(points('صت', '^@Beh 5 ت'), [(0, 5)]);
    expect(points('بت', '^@Beh 5 ت'), isEmpty);
  });

  test('group folds to tooth initial medial strict when final', () {
    expect(points('نت', '@Beh 5 ت'), [(0, 5)]);
    expect(points('يت', '@Beh 5 ت'), [(0, 5)]);
    expect(points('بنت', '@Beh 5 ت'), [(1, 5)]);
    expect(points('تب', 'ت 5 @Beh .'), [(0, 5)]);
    expect(points('تن', 'ت 5 @Beh .'), isEmpty);
  });

  test('ignores comments and blank lines', () {
    expect(points('بت', '# a comment\n\nب2ت  # trailing\n'), [(0, 2)]);
  });

  test('rejects malformed pattern lines', () {
    expect(errMsg('[3ب2ت'), contains('Unterminated length guard'));
    expect(errMsg('[x]ب2ت'), contains('Invalid length guard'));
    expect(errMsg('[x:]ب2ت'), contains('Invalid length guard'));
    expect(errMsg('[2:y]ب2ت'), contains('Invalid length guard'));
    expect(errMsg('[4.5]ب2ت'), contains('Invalid length guard'));
    expect(errMsg('[:3]ب2ت'), contains('Invalid length guard'));
    expect(errMsg('@'), contains('Empty group name'));
    expect(errMsg('='), contains('Empty group name'));
    expect(errMsg('ب.ت'), contains('Token after a trailing'));
    expect(errMsg('5'), contains('Pattern has no letters'));
    expect(errMsg('@Nope 2 ت'), contains('Unknown Unicode Joining_Group name'));
    expect(errMsg('ب3\\6ت'), contains('must not increase'));
    expect(errMsg('ب9\\خت'), contains('Expected a digit after'));
    expect(errMsg('ب\\3ت'), contains('must follow a priority digit'));
    expect(errMsg('{@Beh @Nope} 2 ت'), contains('Unknown Unicode Joining_Group'));
    expect(errMsg('{@Beh Noon} 2 ت'), contains('Stray character'));
    expect(errMsg('> ب2ت'), contains('Stray character'));
    expect(errMsg('{@Beh 2 ت'), contains('Unterminated “{”'));
    expect(errMsg('{} 2 ت'), contains('Empty “{}”'));
    expect(errMsg('ب 2 ^ت'), contains('must be followed by “{”, “@”, or “=”'));
  });

  test('builtin sets resolve and are named', () {
    expect(builtinPatternSetNames(), [
      'arabic-naskh',
      'arabic-nastaliq',
      'arabic-simple',
      'syriac',
    ]);
    for (final name in builtinPatternSetNames()) {
      expect(isBuiltinPatternSet(name), isTrue, reason: name);
      expect(builtinPatternSet(name), isNotNull, reason: name);
    }
    expect(isBuiltinPatternSet('nope'), isFalse);
    expect(builtinPatternSet('nope'), isNull);
  });

  test('the naskh matrix reaches short runs', () {
    List<(int, int)> p(String word) => builtinPoints('arabic-naskh', word);

    expect(p('بط'), [(0, 7)]);
    expect(p('مبط'), [(1, 8)]);
    expect(p('ممبط'), [(0, 3), (2, 9)]);
    expect(p('مممبط'), [(0, 2), (1, 2), (3, 8)]);

    expect(p('بم'), [(0, 4)]);
    expect(p('ممبم'), [(0, 3), (2, 6)]);

    expect(p('بب'), isEmpty);
    expect(p('ممبب'), [(0, 3)]);
  });

  test('naskh allow kashida between initial beh and high medial beh', () {
    List<(int, int)> p(String word) => builtinPoints('arabic-naskh', word);

    expect(p('ببب'), [(0, 2)]);
    expect(p('ببس'), [(0, 2)]);
    expect(p('تبسم'), [(0, 2), (2, 3)]);
    expect(p('ببر'), [(0, 6), (1, 2)]);
    expect(p('ببن'), [(0, 6), (1, 5)]);

    expect(p('ببم'), [(1, 5)]);
    expect(p('بب'), isEmpty);

    expect(p('بببر'), [(2, 3)]);
    expect(p('تبين'), [(2, 6)]);
    expect(p('بببم'), [(0, 2), (2, 6)]);
    expect(p('يتبين'), [(0, 2), (3, 5)]);

    expect(p('مببب'), isEmpty);
  });

  test('nastaliq forbids a kashida after an initial beh', () {
    expect(builtinPoints('arabic-naskh', 'يهتم'), [(0, 6), (1, 6), (2, 6)]);
    expect(builtinPoints('arabic-nastaliq', 'يهتم'), [(1, 6), (2, 6)]);
    expect(builtinPoints('arabic-nastaliq', 'نهتم'), [(1, 6), (2, 6)]);
    expect(
      builtinPoints('arabic-nastaliq', 'فبتم'),
      builtinPoints('arabic-naskh', 'فبتم'),
    );
  });

  test('nastaliq forbids a kashida before a thin join', () {
    expect(builtinPoints('arabic-naskh', 'سقتم'), [(0, 3), (2, 6)]);
    expect(builtinPoints('arabic-nastaliq', 'سقتم'), [(2, 6)]);
    expect(builtinPoints('arabic-naskh', 'متظلم'), [(1, 8), (2, 5)]);
    expect(builtinPoints('arabic-nastaliq', 'متظلم'), [(2, 5)]);
    expect(builtinPoints('arabic-naskh', 'متهم'), [(1, 6)]);
    expect(builtinPoints('arabic-nastaliq', 'متهم'), isEmpty);
    expect(builtinPoints('arabic-nastaliq', 'بحه'), [(1, 5)]);
  });

  test('nastaliq forbids a kashida after a lam or kaf', () {
    for (final word in ['كلمة', 'معلم', 'يكتم']) {
      final pts = builtinPoints('arabic-nastaliq', word);
      final graphemes = word.runes.map(String.fromCharCode).toList();
      for (final (index, _) in pts) {
        expect(
          graphemes[index] == 'ل' || graphemes[index] == 'ك',
          isFalse,
          reason: '$word: $pts',
        );
      }
    }
  });

  test('syriac ranks points outside in', () {
    const expected = <(int, List<int>)>[
      (2, [0]),
      (3, [1, 0]),
      (4, [2, 1, 0]),
      (5, [3, 2, 0, 1]),
      (6, [4, 3, 2, 0, 1]),
      (7, [5, 4, 3, 0, 1, 2]),
      (8, [6, 5, 4, 3, 0, 1, 2]),
      (9, [7, 6, 5, 4, 0, 1, 2, 3]),
      (10, [8, 7, 6, 5, 4, 0, 1, 2, 3]),
    ];
    for (final (letters, order) in expected) {
      final word = 'ܒ' * letters;
      final ranked = builtinPoints('syriac', word)
        ..sort((a, b) {
          final byPriority = b.$2.compareTo(a.$2);
          if (byPriority != 0) {
            return byPriority;
          }
          return a.$1.compareTo(b.$1);
        });
      expect(
        ranked.map((e) => e.$1).toList(),
        order,
        reason: 'run of $letters letters',
      );
    }
  });

  test('syriac matches the libreoffice test vectors', () {
    List<int> ranked(String word) {
      final pts = builtinPoints('syriac', word)
        ..sort((a, b) {
          final byPriority = b.$2.compareTo(a.$2);
          if (byPriority != 0) {
            return byPriority;
          }
          return a.$1.compareTo(b.$1);
        });
      return pts.map((e) => e.$1).toList();
    }

    expect(ranked('ܥܥܥܥܥܥܥ'), [5, 4, 3, 0, 1, 2]);
    expect(
      ranked('ܥܥܥܥܥ\u{073F}\u{073E}ܥ\u{073F}\u{073E}ܥ\u{073F}\u{073E}'),
      [5, 4, 3, 0, 1, 2],
    );
    expect(ranked('ܥܥـܥܥܥܥ')[0], 2);
  });

  test('syriac never breaks lomadh olaph', () {
    expect(builtinPoints('syriac', 'ܠܐ'), isEmpty);
    expect(builtinPoints('syriac', 'ܠܒ'), [(0, 8)]);
  });

  test('syriac letters that take no kashida after them', () {
    for (final word in ['ܐܒ', 'ܕܒ', 'ܗܒ', 'ܘܒ', 'ܙܒ', 'ܨܒ', 'ܪܒ', 'ܬܒ', 'ܖܒ']) {
      expect(builtinPoints('syriac', word), isEmpty, reason: word);
    }
  });

  test('syriac ladders apply to each joined run', () {
    expect(builtinPoints('syriac', 'ܡܪܝܡ'), [(0, 8), (2, 8)]);
    expect(builtinPoints('syriac', 'ܡـܝܡ'), [(0, 3), (1, 9), (2, 8)]);
  });

  test('naskh pattern tests', () {
    expect(builtinPoints('arabic-naskh', 'بحه'), [(1, 9)]);
    expect(builtinPoints('arabic-naskh', 'مسعد'), [(2, 3)]);
    expect(builtinPoints('arabic-naskh', 'كلمة'), [(2, 9)]);
    expect(builtinPoints('arabic-naskh', 'سعي'), isEmpty);
    expect(builtinPoints('arabic-naskh', 'به'), [(0, 9)]);
  });

  test('simple pattern tests', () {
    expect(builtinPoints('arabic-simple', 'سبت'), [(0, 8), (1, 3)]);
    expect(builtinPoints('arabic-simple', 'سي'), [(0, 8)]);
    expect(builtinPoints('arabic-simple', 'بيبت'), [(2, 3)]);
    expect(builtinPoints('arabic-simple', 'بني'), [(0, 5), (1, 3)]);
  });

  test('zwnj breaks the join', () {
    expect(points('ب\u{200C}ت', 'ب2ت'), isEmpty);
    expect(builtinPoints('arabic-simple', 'ب\u{200C}ت'), isEmpty);
    final g = splitGraphemes('ب\u{200C}ت');
    expect(formOf(g, 0), JoiningForm.isolated);
    expect(formOf(g, 1), JoiningForm.isolated);
  });

  test('stray pattern characters are rejected', () {
    expect(errMsg('{=Seen x} 5 ت'), contains('Stray character'));
    expect(errMsg('ب\u{0662}ت'), contains('Stray character'));
    expect(errMsg('ب2ت]'), contains('Stray character'));
    expect(errMsg('[2] > ب2ت'), contains('Stray character'));
    expect(errMsg('ب2ت // note'), contains('Stray character'));
  });

  test('zwj zwnj', () {
    expect(points('د\u{200D}ب', 'د2ب'), isEmpty);
    expect(points('ب\u{200D}ت', 'ب2ت'), [(0, 2)]);
    expect(points('ب\u{200D}\u{200C}ت', 'ب2ت'), isEmpty);
    expect(points('ب\u{200C}\u{200D}ت', 'ب2ت'), isEmpty);
    expect(points('سف', '8 ف .'), [(0, 8)]);
    expect(points('سف\u{200D}', '8 ف .'), isEmpty);
  });

  test('manual tatweel', () {
    final set = builtinPatternSet('arabic-simple')!;
    const seated = 'ب\u{0640}\u{064E}\u{0654}ت';
    expect(findKashidaPoints(seated, set, true).$1, seated);
    const below = 'ب\u{0640}\u{0655}ت';
    expect(findKashidaPoints(below, set, true).$1, below);
    const harakah = 'ب\u{0640}\u{064E}ت';
    expect(findKashidaPoints(harakah, set, true).$1, harakah);
    expect(points('بـتر', '[4]ت2ر'), [(2, 2)]);
    expect(points('بـت', 'ب2*'), [(0, 2)]);
    expect(points('بـت', 'ـ 9'), [(1, 9)]);
    expect(points('بـت', '@Tatweel 9'), [(1, 9)]);
    final naskh = builtinPatternSet('arabic-naskh')!;
    final merged = findKashidaPoints('سـبل', naskh, false).$2
        .map((k) => (k.index, k.priority))
        .toList();
    expect(merged, [(2, 3)]);
  });

  test('existing kashida matches like any letter', () {
    final set = compilePatternText('ـ 5');
    final pts = findKashidaPoints('بـت', set, false).$2
        .map((k) => (k.index, k.priority))
        .toList();
    expect(pts, [(1, 5)]);
    expect(findKashidaPoints('بـت', set, true).$2, isEmpty);
  });

  test('conflicting weights at one connection are rejected', () {
    expect(errMsg('ب2 3ت'), contains('Conflicting weights'));
    expect(errMsg('ب!2ت'), contains('Conflicting weights'));
  });

  test('degenerate length guards are rejected', () {
    expect(errMsg('[0]ب2ت'), contains('Invalid length guard'));
    expect(errMsg('[1]ب2ت'), contains('Invalid length guard'));
    expect(errMsg('[1:]ب2ت'), contains('Invalid length guard'));
    expect(errMsg('[3:2]ب2ت'), contains('Invalid length guard'));
  });

  test('boundary edge weights are rejected', () {
    expect(errMsg('. 5 ب ت'), contains('Weight outside the run'));
    expect(errMsg('ب 5 .'), contains('Weight outside the run'));
  });

  test('group name stops at non name characters', () {
    expect(points('بتت', '@Behت 2 ت'), [(1, 2)]);
  });

  test('a seat kashida is transparent', () {
    final set = builtinPatternSet('arabic-naskh')!;
    const cases = <(String, List<(int, int)>, List<(int, int)>)>[
      ('ٱلرَّحۡمَـٰنِ', [(3, 2), (5, 2)], [(3, 2), (4, 2)]),
      ('ٱلۡعَـٰلَمِینَ', [(3, 1), (6, 4)], [(2, 1), (5, 4)]),
      ('وَبِٱلۡـَٔاخِرَةِ', [(1, 4), (6, 1)], [(1, 4), (5, 1)]),
      ('ٱلنَّبِیِّـۧنَ', [(5, 5)], [(4, 5)]),
      ('تَأۡمَـ۫نَّا', [(0, 4), (4, 5)], [(0, 4), (3, 5)]),
      ('لِیَسُـࣳۤـُٔوا۟', [], []),
      ('ٱلصَّـٰلِحَـٰتِ', [(3, 5)], [(2, 5)]),
    ];
    for (final (word, seated, bare) in cases) {
      expect(findKashidaPoints(word, set, true).$1, word, reason: word);
      expect(builtinPoints('arabic-naskh', word), seated, reason: word);
      final stripped = String.fromCharCodes(
        word.runes.where((c) => c != 0x0640),
      );
      expect(builtinPoints('arabic-naskh', stripped), bare, reason: word);
    }

    const seated = 'ٱلۡعَـٰلَمِینَ';
    expect(points(seated, '[6]م2ی'), [(5, 2)]);
    expect(points(seated, '[7]م2ی'), isEmpty);
    expect(points(seated, 'ـ 9'), isEmpty);
    const typed = 'ٱلۡعَـٰلَـمِینَ';
    expect(points(typed, '[7]م2ی'), [(6, 2)]);
    expect(points(typed, 'ـ 9'), [(5, 9)]);
  });

  test('find kashida points strips or keeps user tatweel', () {
    final set = builtinPatternSet('arabic-simple')!;
    expect(findKashidaPoints('بـت', set, true).$1, 'بت');
    final kept = findKashidaPoints('بـت', set, false);
    expect(kept.$1, 'بـت');
    expect(kept.$2.any((k) => k.index == 1 && k.priority == 9), isTrue);
  });

  test('readme length ladder words', () {
    List<(int, int)> p(String w) => points(w, '[4:] @Beh 9\\6 @Ain');
    expect(p('بعثة'), [(0, 9)]);
    expect(p('مبتعث'), [(2, 8)]);
    expect(p('المبتعث'), [(4, 7)]);
    expect(p('المبتعثة'), [(4, 6)]);
  });

  test('every connection in a run already joins', () {
    const words =
        'بيت لا دب بد مررت الله سـبح ب\u{200C}ت ب\u{200D}ت نَّص \u{064E}بت بـ وا أبد كتاب لآ دا';
    for (final word in words.split(' ')) {
      final graphemes = splitGraphemes(word);
      for (final run in joinedRuns(graphemes)) {
        final hosts = run.sublist(0, run.length - 1);
        for (final index in hosts) {
          expect(
            joinsLeft(graphemes, index),
            isTrue,
            reason: '$word: grapheme $index does not join forward',
          );
        }
      }
    }
  });

  test('a later rule overrides an earlier one', () {
    expect(points('بتم', 'ب3ت\nت5م\nب1ت'), [(0, 1), (1, 5)]);
  });

  test('a later rule can undo a suppression and impose one', () {
    expect(points('بت', 'ب!ت\nب5ت'), [(0, 5)]);
    expect(points('بت', 'ب5ت\nب!ت'), isEmpty);
  });

  test('use splices a builtin in', () {
    expect(builtinPoints('arabic-naskh', 'بحه'), [(1, 9)]);
    expect(points('بحه', 'use arabic-naskh\n* 2 @Heh .'), [(1, 2)]);
    expect(points('بحه', 'use arabic-naskh'), [(1, 9)]);
  });

  test('rejects malformed imports', () {
    expect(errMsg('use nope'), contains('Unknown pattern set'));
    expect(errMsg('used arabic-naskh'), contains('Stray character'));
  });
}
