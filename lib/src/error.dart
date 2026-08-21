/// An error while compiling pattern text.
class CompileError implements Exception {
  const CompileError({required this.kind, required this.lineNumber});

  /// What went wrong.
  final CompileErrorKind kind;

  /// 1-based line number into the compiled pattern text.
  final int lineNumber;

  @override
  String toString() => 'line $lineNumber: $kind';
}

/// What went wrong on a pattern line.
sealed class CompileErrorKind {
  const CompileErrorKind();
}

class InvalidLengthGuard extends CompileErrorKind {
  const InvalidLengthGuard(this.body);
  final String body;

  @override
  String toString() => 'Invalid length guard “[$body]”';
}

class UnterminatedLengthGuard extends CompileErrorKind {
  const UnterminatedLengthGuard();

  @override
  String toString() => 'Unterminated length guard';
}

class UnterminatedGroupSet extends CompileErrorKind {
  const UnterminatedGroupSet();

  @override
  String toString() => 'Unterminated “{” group set';
}

class EmptyGroupSet extends CompileErrorKind {
  const EmptyGroupSet();

  @override
  String toString() => 'Empty “{}” group set';
}

class UnknownGroupName extends CompileErrorKind {
  const UnknownGroupName(this.name);
  final String name;

  @override
  String toString() => 'Unknown Unicode Joining_Group name “$name”';
}

class TokenAfterTrailingBoundary extends CompileErrorKind {
  const TokenAfterTrailingBoundary();

  @override
  String toString() => 'Token after a trailing “.” boundary';
}

class ExpectedDigitAfterBackslash extends CompileErrorKind {
  const ExpectedDigitAfterBackslash();

  @override
  String toString() => 'Expected a digit after “\\”';
}

class IncreasingPriority extends CompileErrorKind {
  const IncreasingPriority({required this.base, required this.min});
  final int base;
  final int min;

  @override
  String toString() => 'Priority must not increase ($base\\$min)';
}

class BackslashWithoutDigit extends CompileErrorKind {
  const BackslashWithoutDigit();

  @override
  String toString() => '“\\” must follow a priority digit';
}

class CaretNotFollowed extends CompileErrorKind {
  const CaretNotFollowed();

  @override
  String toString() => '“^” must be followed by “{”, “@”, or “=”';
}

class EmptyGroupName extends CompileErrorKind {
  const EmptyGroupName();

  @override
  String toString() => 'Empty group name';
}

class NoLetters extends CompileErrorKind {
  const NoLetters();

  @override
  String toString() => 'Pattern has no letters';
}

class StrayCharacter extends CompileErrorKind {
  const StrayCharacter(this.character);
  final int character;

  @override
  String toString() => "Stray character '${String.fromCharCode(character)}'";
}

class ConflictingWeights extends CompileErrorKind {
  const ConflictingWeights();

  @override
  String toString() => 'Conflicting weights at one connection';
}

class WeightOutsideRun extends CompileErrorKind {
  const WeightOutsideRun();

  @override
  String toString() => 'Weight outside the run at a “.” boundary';
}

class UnknownImport extends CompileErrorKind {
  const UnknownImport(this.name);
  final String name;

  @override
  String toString() => 'Unknown pattern set “$name”';
}
