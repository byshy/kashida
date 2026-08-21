import 'data/arabic_naskh.dart';
import 'data/arabic_nastaliq.dart';
import 'data/arabic_simple.dart';
import 'data/syriac.dart';
import 'pattern.dart';

final Map<String, PatternSet> _cache = {};

const _builtinPatternSetNames = <String>[
  'arabic-naskh',
  'arabic-nastaliq',
  'arabic-simple',
  'syriac',
];

/// Names of the built-in pattern sets, in a stable order.
///
/// Currently `arabic-naskh`, `arabic-nastaliq`, `arabic-simple`, and `syriac`.
List<String> builtinPatternSetNames() => _builtinPatternSetNames;

/// Whether [name] is one of [builtinPatternSetNames].
bool isBuiltinPatternSet(String name) => _builtinPatternSetNames.contains(name);

/// The compiled built-in set named [name], or `null` if it is unknown.
///
/// Prefer [requiredBuiltinPatternSet] in application code. Use this when you
/// are probing a name that may not exist.
///
/// Results are cached. Pass the same names as in [builtinPatternSetNames].
PatternSet? builtinPatternSet(String name) {
  final cached = _cache[name];
  if (cached != null) {
    return cached;
  }
  final String text;
  switch (name) {
    case 'arabic-naskh':
      text = arabicNaskhPatternText;
    case 'arabic-nastaliq':
      text = arabicNastaliqPatternText;
    case 'arabic-simple':
      text = arabicSimplePatternText;
    case 'syriac':
      text = syriacPatternText;
    default:
      return null;
  }
  final compiled = compilePatternText(text);
  final tagged = PatternSet(compiled.patterns, id: name);
  _cache[name] = tagged;
  return tagged;
}

/// The compiled built-in set named [name].
///
/// Throws [ArgumentError] if [name] is not in [builtinPatternSetNames].
PatternSet requiredBuiltinPatternSet(String name) {
  final set = builtinPatternSet(name);
  if (set == null) {
    throw ArgumentError.value(name, 'name', 'Unknown built-in pattern set');
  }
  return set;
}
