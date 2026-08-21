/// Finding kashida (tatweel) insertion points and priorities, driven by a
/// small pattern language.
///
/// Compile rules with [compilePatternText] or [requiredBuiltinPatternSet],
/// then either [findKashidaPoints], [insertKashida], [layoutParagraph],
/// or [KashidaText].
library;

export 'src/builtin.dart';
export 'src/error.dart';
export 'src/flutter_measure.dart';
export 'src/kashida_core.dart';
export 'src/kashida_text.dart';
export 'src/layout.dart';
export 'src/pattern.dart' show compilePatternText, PatternSet;
