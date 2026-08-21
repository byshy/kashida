import 'package:characters/characters.dart';

import 'grapheme.dart';
import 'pattern.dart';
import 'resolve.dart';

export 'grapheme.dart' show kashida, kashidaCodepoint;

/// A point where a kashida may be inserted.
class KashidaPoint {
  /// Creates a point after grapheme cluster [index] with [priority] 0–9.
  const KashidaPoint({required this.index, required this.priority});

  /// The grapheme cluster index the kashida goes after.
  final int index;

  /// The kashida point priority, from 0–9. Higher is more preferable.
  final int priority;

  @override
  bool operator ==(Object other) =>
      other is KashidaPoint &&
      other.index == index &&
      other.priority == priority;

  @override
  int get hashCode => Object.hash(index, priority);

  @override
  String toString() => 'KashidaPoint(index: $index, priority: $priority)';
}

/// Cleaned text and the kashida points that refer to it.
class KashidaAnalysis {
  /// Creates an analysis of [text] with [points] whose indices refer to it.
  const KashidaAnalysis({required this.text, required this.points});

  /// Text after optional bare-tatweel stripping.
  final String text;

  /// Insertion points into [text], as grapheme-cluster indices.
  final List<KashidaPoint> points;

  /// [text] with tatweel inserted at [points].
  String insert({int count = 1, int minPriority = 0}) =>
      insertKashidaAt(text, points, count: count, minPriority: minPriority);

  @override
  bool operator ==(Object other) =>
      other is KashidaAnalysis &&
      other.text == text &&
      _samePoints(other.points, points);

  @override
  int get hashCode => Object.hash(text, Object.hashAll(points));

  @override
  String toString() => 'KashidaAnalysis($text, $points)';
}

bool _samePoints(List<KashidaPoint> a, List<KashidaPoint> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

/// Kashida insertion points for [text] from [set] alone.
///
/// Unlike [findKashidaPoints], this does not strip existing tatweel.
/// Indices are grapheme-cluster offsets into [text] as given.
List<KashidaPoint> findKashidaPointsPatterns(String text, PatternSet set) {
  final graphemes = splitGraphemes(text);
  final out = <KashidaPoint>[];
  for (final run in joinedRuns(graphemes)) {
    out.addAll(resolveRun(graphemes, run, set));
  }
  return out;
}

/// [text] with bare tatweel (U+0640) removed.
///
/// A tatweel that carries a combining mark is kept, because it is a seat for
/// that mark rather than an elongation.
String stripBareTatweel(String text) {
  if (!text.contains(kashida)) {
    return text;
  }
  final chars = text.runes.toList();
  final out = StringBuffer();
  for (var k = 0; k < chars.length; k++) {
    if (isBareTatweelAt(chars, k)) {
      continue;
    }
    out.writeCharCode(chars[k]);
  }
  return out.toString();
}

/// Kashida insertion points for [text] under the given pattern set.
///
/// Any **bare** kashida already in the text is stripped first, unless
/// [removeExistingKashida] is `false`. A kashida carrying a mark serves as
/// a seat for it, so it is always kept.
///
/// Point indices refer to the returned [KashidaAnalysis.text].
KashidaAnalysis findKashidaPoints(
  String text,
  PatternSet set, {
  bool removeExistingKashida = true,
}) {
  final cleaned = removeExistingKashida ? stripBareTatweel(text) : text;
  return KashidaAnalysis(
    text: cleaned,
    points: findKashidaPointsPatterns(cleaned, set),
  );
}

/// Inserts [count] tatweels after each grapheme listed in [points].
///
/// Points with [KashidaPoint.priority] below [minPriority] are skipped.
/// Inserts from the end of the string so earlier indices stay valid.
String insertKashidaAt(
  String text,
  Iterable<KashidaPoint> points, {
  int count = 1,
  int minPriority = 0,
}) {
  if (count < 0) {
    throw ArgumentError.value(count, 'count', 'must be >= 0');
  }
  if (count == 0) {
    return text;
  }
  final clusters = text.characters.toList();
  final tatweel = kashida * count;
  final sorted = points.where((p) => p.priority >= minPriority).toList()
    ..sort((a, b) => b.index.compareTo(a.index));
  for (final point in sorted) {
    if (point.index < 0 || point.index >= clusters.length) {
      throw RangeError.index(point.index, clusters, 'index');
    }
    clusters.insert(point.index + 1, tatweel);
  }
  return clusters.join();
}

/// Finds kashida points in [text] and returns the string with tatweel inserted.
String insertKashida(
  String text,
  PatternSet set, {
  bool removeExistingKashida = true,
  int count = 1,
  int minPriority = 0,
}) {
  return findKashidaPoints(
    text,
    set,
    removeExistingKashida: removeExistingKashida,
  ).insert(count: count, minPriority: minPriority);
}
