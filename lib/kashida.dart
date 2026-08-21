/// Finding kashida (tatweel) insertion points and priorities, driven by a
/// small pattern language.
///
/// Compile rules with [compilePatternText] or load a built-in set with
/// [builtinPatternSet], then call [findKashidaPoints] or [insertKashida].
library;

export 'src/builtin.dart';
export 'src/error.dart';
export 'src/kashida_core.dart';
export 'src/layout.dart';
export 'src/pattern.dart' show compilePatternText, PatternSet, CompiledPattern;
