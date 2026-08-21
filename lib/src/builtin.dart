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

List<String> builtinPatternSetNames() => _builtinPatternSetNames;

bool isBuiltinPatternSet(String name) => _builtinPatternSetNames.contains(name);

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
  final set = compilePatternText(text);
  _cache[name] = set;
  return set;
}
