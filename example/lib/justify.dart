import 'package:characters/characters.dart';
import 'package:flutter/painting.dart';
import 'package:kashida/kashida.dart';

const kashidaChar = '\u{0640}';

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

class KashidaSlot {
  KashidaSlot({
    required this.offset,
    required this.priority,
  });

  final int offset;
  final int priority;
  int count = 0;
}

class LayoutWord {
  LayoutWord({required this.text, required this.points});

  final String text;
  final List<KashidaSlot> points;
}

class JustifiedLine {
  const JustifiedLine({
    required this.words,
    required this.stretch,
  });

  final List<LayoutWord> words;
  final bool stretch;

  String get text => words.map(elongated).join(' ');
}

String elongated(LayoutWord word) {
  var out = word.text;
  for (final point in word.points.reversed) {
    if (point.count == 0) {
      continue;
    }
    out =
        '${out.substring(0, point.offset)}'
        '${kashidaChar * point.count}'
        '${out.substring(point.offset)}';
  }
  return out;
}

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

double elongatedWidth(
  List<LayoutWord> words,
  TextStyle style, {
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return measureWidth(
    words.map(elongated).join(' '),
    style,
    textScaler: textScaler,
  );
}

int _stringOffsetAfterGrapheme(String text, int graphemeIndex) {
  final graphemes = text.characters;
  return graphemes.take(graphemeIndex + 1).toString().length;
}

List<LayoutWord> _wordsFromText(
  String text,
  PatternSet set, {
  required bool removeExistingKashida,
}) {
  final words = <LayoutWord>[];
  for (final word in text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty)) {
    final (cleaned, found) = findKashidaPoints(
      word,
      set,
      removeExistingKashida,
    );
    words.add(
      LayoutWord(
        text: cleaned,
        points: [
          for (final point in found)
            KashidaSlot(
              offset: _stringOffsetAfterGrapheme(cleaned, point.index),
              priority: point.priority,
            ),
        ],
      ),
    );
  }
  return words;
}

List<List<LayoutWord>> _breakLines(
  List<LayoutWord> words,
  double width,
  TextStyle style,
  TextScaler textScaler,
) {
  final lines = <List<LayoutWord>>[];
  var line = <LayoutWord>[];
  for (final word in words) {
    if (line.isNotEmpty &&
        elongatedWidth([...line, word], style, textScaler: textScaler) >
            width) {
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
  List<LayoutWord> words,
  KashidaSlot point,
  double width,
  TextStyle style,
  TextScaler textScaler, {
  required int min,
  required int max,
}) {
  final before = point.count;
  if (before >= max) {
    return false;
  }
  point.count = before == 0 ? (min < max ? min : max) : before + 1;
  if (elongatedWidth(words, style, textScaler: textScaler) <= width) {
    return true;
  }
  point.count = before;
  return false;
}

void _fillSlots(
  List<LayoutWord> words,
  List<KashidaSlot> slots,
  double width,
  TextStyle style,
  TextScaler textScaler, {
  required int min,
  required int max,
}) {
  bool short() =>
      elongatedWidth(words, style, textScaler: textScaler) < width;
  while (short()) {
    var progressed = false;
    for (final point in slots) {
      if (!short()) {
        break;
      }
      if (_insert(
        words,
        point,
        width,
        style,
        textScaler,
        min: min,
        max: max,
      )) {
        progressed = true;
      }
    }
    if (!progressed) {
      break;
    }
  }
}

void _justifyArabic(
  List<LayoutWord> words,
  double width,
  TextStyle style,
  TextScaler textScaler, {
  required int min,
  required int max,
}) {
  bool short() =>
      elongatedWidth(words, style, textScaler: textScaler) < width;

  final byPriority = <int, List<(LayoutWord, KashidaSlot)>>{};
  for (final word in words) {
    for (final point in word.points) {
      byPriority.putIfAbsent(point.priority, () => []).add((word, point));
    }
  }
  final taken = <LayoutWord>{};
  final priorities = byPriority.keys.toList()..sort((a, b) => b.compareTo(a));
  for (final priority in priorities) {
    if (!short()) {
      break;
    }
    final perWord = <LayoutWord, KashidaSlot>{};
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
      while (_insert(
        words,
        point,
        width,
        style,
        textScaler,
        min: min,
        max: max,
      )) {
        taken.add(word);
      }
    }
  }

  final slots = [
    for (final word in words)
      for (final point in word.points)
        if (point.count > 0) point,
  ].reversed.toList();
  _fillSlots(words, slots, width, style, textScaler, min: min, max: max);
}

void _justifySyriac(
  List<LayoutWord> words,
  double width,
  TextStyle style,
  TextScaler textScaler, {
  required int min,
  required int max,
}) {
  final slots = [
    for (final word in words)
      if (word.points.isNotEmpty)
        word.points.reduce((a, b) => a.priority >= b.priority ? a : b),
  ];
  _fillSlots(words, slots, width, style, textScaler, min: min, max: max);
}

List<JustifiedLine> layoutParagraph(
  String text,
  PatternSet set,
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
  final words = _wordsFromText(
    text,
    set,
    removeExistingKashida: removeExistingKashida,
  );
  final broken = _breakLines(words, width, style, textScaler);
  final justify = syriac ? _justifySyriac : _justifyArabic;

  final out = <JustifiedLine>[];
  for (var index = 0; index < broken.length; index++) {
    final line = broken[index];
    final stretch = justified && index < broken.length - 1;
    if (stretch && applyKashida) {
      justify(
        line,
        width,
        style,
        textScaler,
        min: minKashidas,
        max: maxKashidas,
      );
    }
    out.add(JustifiedLine(words: line, stretch: stretch));
  }
  return out;
}
