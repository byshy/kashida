import 'kashida_core.dart';
import 'pattern.dart';

/// Measures the width of a string in the caller's units (pixels, ems, …).
typedef KashidaMeasure = double Function(String text);

/// How leftover line width is filled with tatweel.
enum KashidaFillStyle {
  /// Highest-priority point per word, then remaining slots (naskh-like).
  arabic,

  /// Highest-priority point in each word only (Syriac-like).
  syriac,
}

/// Default fill for a pattern set: Syriac builtins use [KashidaFillStyle.syriac].
KashidaFillStyle fillStyleFor(PatternSet set) {
  return set.id == 'syriac' ? KashidaFillStyle.syriac : KashidaFillStyle.arabic;
}

class _Slot {
  _Slot({required this.offset, required this.priority});

  final int offset;
  final int priority;
  int count = 0;
}

/// A word on a justified line, with kashida slots into [text].
class KashidaWord {
  KashidaWord({required this.text, required List<KashidaPoint> points})
    : _slots = [
        for (final point in points)
          _Slot(offset: point.endOffsetIn(text), priority: point.priority),
      ];

  /// Word text (after optional tatweel stripping), without fill tatweels.
  final String text;

  final List<_Slot> _slots;

  /// [text] with the chosen number of tatweels inserted.
  String elongated() {
    var out = text;
    for (final point in _slots.reversed) {
      if (point.count == 0) {
        continue;
      }
      out =
          '${out.substring(0, point.offset)}'
          '${kashida * point.count}'
          '${out.substring(point.offset)}';
    }
    return out;
  }
}

/// One wrapped line of [KashidaWord]s.
class KashidaLine {
  /// Creates a line. [stretch] is true when the line is filled to the target width.
  const KashidaLine({required this.words, required this.stretch});

  /// Words on this line, in logical order.
  final List<KashidaWord> words;

  /// Whether this line should be stretched to the target width.
  final bool stretch;

  /// The line as a single string with spaces between elongated words.
  String get text => words.map((w) => w.elongated()).join(' ');

  /// Width still unused after tatweel fill, in [measure] units.
  ///
  /// Spread this between words in the UI (the example uses a `Row`).
  double unusedWidth(double width, KashidaMeasure measure) {
    final extra = width - measure(text);
    if (!extra.isFinite || extra <= 0) {
      return 0;
    }
    return extra;
  }
}

double _elongatedWidth(List<KashidaWord> words, KashidaMeasure measure) {
  return measure(words.map((w) => w.elongated()).join(' '));
}

List<KashidaWord> _wordsFromText(
  String text,
  PatternSet set, {
  required bool removeExistingKashida,
}) {
  final words = <KashidaWord>[];
  for (final word in text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty)) {
    final found = findKashidaPoints(
      word,
      set,
      removeExistingKashida: removeExistingKashida,
    );
    words.add(KashidaWord(text: found.text, points: found.points));
  }
  return words;
}

List<List<KashidaWord>> _breakLines(
  List<KashidaWord> words,
  double width,
  KashidaMeasure measure,
) {
  final lines = <List<KashidaWord>>[];
  var line = <KashidaWord>[];
  for (final word in words) {
    if (line.isNotEmpty && _elongatedWidth([...line, word], measure) > width) {
      lines.add(line);
      line = [word];
    } else {
      line.add(word);
    }
  }
  if (line.isNotEmpty) {
    lines.add(line);
  }
  return lines;
}

bool _insert(
  List<KashidaWord> words,
  _Slot point,
  double width,
  KashidaMeasure measure, {
  required int min,
  required int max,
}) {
  final before = point.count;
  if (before >= max) {
    return false;
  }
  point.count = before == 0 ? (min < max ? min : max) : before + 1;
  if (_elongatedWidth(words, measure) <= width) {
    return true;
  }
  point.count = before;
  return false;
}

void _fillSlots(
  List<KashidaWord> words,
  List<_Slot> slots,
  double width,
  KashidaMeasure measure, {
  required int min,
  required int max,
}) {
  bool short() => _elongatedWidth(words, measure) < width;
  while (short()) {
    var progressed = false;
    for (final point in slots) {
      if (!short()) {
        break;
      }
      if (_insert(words, point, width, measure, min: min, max: max)) {
        progressed = true;
      }
    }
    if (!progressed) {
      break;
    }
  }
}

void _justifyArabic(
  List<KashidaWord> words,
  double width,
  KashidaMeasure measure, {
  required int min,
  required int max,
}) {
  bool short() => _elongatedWidth(words, measure) < width;

  final byPriority = <int, List<(KashidaWord, _Slot)>>{};
  for (final word in words) {
    for (final point in word._slots) {
      byPriority.putIfAbsent(point.priority, () => []).add((word, point));
    }
  }
  final taken = <KashidaWord>{};
  final priorities = byPriority.keys.toList()..sort((a, b) => b.compareTo(a));
  for (final priority in priorities) {
    if (!short()) {
      break;
    }
    final perWord = <KashidaWord, _Slot>{};
    for (final (word, point) in byPriority[priority]!) {
      if (taken.contains(word)) {
        continue;
      }
      final current = perWord[word];
      if (current == null || point.offset > current.offset) {
        perWord[word] = point;
      }
    }
    for (final word in perWord.keys.toList().reversed) {
      if (!short()) {
        break;
      }
      final point = perWord[word]!;
      while (_insert(words, point, width, measure, min: min, max: max)) {
        taken.add(word);
      }
    }
  }

  final slots = [
    for (final word in words)
      for (final point in word._slots)
        if (point.count > 0) point,
  ].reversed.toList();
  _fillSlots(words, slots, width, measure, min: min, max: max);
}

void _justifySyriac(
  List<KashidaWord> words,
  double width,
  KashidaMeasure measure, {
  required int min,
  required int max,
}) {
  final slots = [
    for (final word in words)
      if (word._slots.isNotEmpty)
        word._slots.reduce((a, b) => a.priority >= b.priority ? a : b),
  ];
  _fillSlots(words, slots, width, measure, min: min, max: max);
}

/// Wraps [text] to [width] and optionally fills lines with tatweel.
///
/// [measure] is the only font/metrics hook: return the width of a string in
/// the same units as [width]. Unless [justifyLastLine] is true, the last line
/// of each newline-separated paragraph is not stretched.
///
/// [insertKashida] is a different operation: it does not wrap or honor width.
///
/// If [fill] is omitted, [fillStyleFor] picks Syriac fill for the `syriac`
/// builtin and Arabic fill otherwise. [minKashidas] defaults to 1, matching
/// [insertKashida]'s per-point count.
List<KashidaLine> layoutParagraph(
  String text,
  PatternSet set, {
  required double width,
  required KashidaMeasure measure,
  int minKashidas = 1,
  int maxKashidas = 4,
  bool justified = true,
  bool justifyLastLine = false,
  bool applyKashida = true,
  bool removeExistingKashida = true,
  KashidaFillStyle? fill,
}) {
  final fillStyle = fill ?? fillStyleFor(set);
  final out = <KashidaLine>[];
  for (final block in text.split('\n')) {
    if (block.trim().isEmpty) {
      continue;
    }
    out.addAll(
      _layoutBlock(
        block,
        set,
        width: width,
        measure: measure,
        minKashidas: minKashidas,
        maxKashidas: maxKashidas,
        justified: justified,
        justifyLastLine: justifyLastLine,
        applyKashida: applyKashida,
        removeExistingKashida: removeExistingKashida,
        fill: fillStyle,
      ),
    );
  }
  return out;
}

List<KashidaLine> _layoutBlock(
  String text,
  PatternSet set, {
  required double width,
  required KashidaMeasure measure,
  required int minKashidas,
  required int maxKashidas,
  required bool justified,
  required bool justifyLastLine,
  required bool applyKashida,
  required bool removeExistingKashida,
  required KashidaFillStyle fill,
}) {
  final words = _wordsFromText(
    text,
    set,
    removeExistingKashida: removeExistingKashida,
  );
  final broken = _breakLines(words, width, measure);
  final justify = fill == KashidaFillStyle.syriac
      ? _justifySyriac
      : _justifyArabic;

  final out = <KashidaLine>[];
  for (var index = 0; index < broken.length; index++) {
    final line = broken[index];
    final isLast = index == broken.length - 1;
    final stretch = justified && (!isLast || justifyLastLine);
    if (stretch && applyKashida) {
      justify(line, width, measure, min: minKashidas, max: maxKashidas);
    }
    out.add(KashidaLine(words: line, stretch: stretch));
  }
  return out;
}
