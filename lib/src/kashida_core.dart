import 'grapheme.dart';
import 'pattern.dart';
import 'resolve.dart';

/// A point where a kashida may be inserted.
class KashidaPoint {
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

/// Kashida insertion points for [text] from the pattern set alone.
List<KashidaPoint> findKashidaPointsPatterns(String text, PatternSet set) {
  final graphemes = splitGraphemes(text);
  final out = <KashidaPoint>[];
  for (final run in joinedRuns(graphemes)) {
    out.addAll(resolveRun(graphemes, run, set));
  }
  return out;
}

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
/// Returns the (possibly stripped) text along with the points, whose
/// indices refer to it.
(String, List<KashidaPoint>) findKashidaPoints(
  String text,
  PatternSet set,
  bool removeExistingKashida,
) {
  final cleaned = removeExistingKashida ? stripBareTatweel(text) : text;
  return (cleaned, findKashidaPointsPatterns(cleaned, set));
}
