/// An error while compiling pattern text.
class CompileError implements Exception {
  /// Creates an error for [kind] on 1-based [lineNumber].
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
  /// Creates a compile-error kind.
  const CompileErrorKind();
}

/// A `[…]` length guard could not be parsed.
class InvalidLengthGuard extends CompileErrorKind {
  /// Creates an error for the unparsed guard body.
  const InvalidLengthGuard(this.body);

  /// Text inside the square brackets.
  final String body;

  @override
  String toString() => 'Invalid length guard “[$body]”';
}

/// A `[` length guard was not closed before the end of the line.
class UnterminatedLengthGuard extends CompileErrorKind {
  /// Creates an unterminated-guard error.
  const UnterminatedLengthGuard();

  @override
  String toString() => 'Unterminated length guard';
}

/// A `{` group set was not closed before the end of the line.
class UnterminatedGroupSet extends CompileErrorKind {
  /// Creates an unterminated-group-set error.
  const UnterminatedGroupSet();

  @override
  String toString() => 'Unterminated “{” group set';
}

/// A `{}` group set contained no members.
class EmptyGroupSet extends CompileErrorKind {
  /// Creates an empty-group-set error.
  const EmptyGroupSet();

  @override
  String toString() => 'Empty “{}” group set';
}

/// A `@Name` or `=Name` token used an unknown Joining_Group.
class UnknownGroupName extends CompileErrorKind {
  /// Creates an error for [name].
  const UnknownGroupName(this.name);

  /// The unknown group name, including the `@` or `=` prefix.
  final String name;

  @override
  String toString() => 'Unknown Unicode Joining_Group name “$name”';
}

/// A token appeared after a trailing `.` word boundary.
class TokenAfterTrailingBoundary extends CompileErrorKind {
  /// Creates a token-after-boundary error.
  const TokenAfterTrailingBoundary();

  @override
  String toString() => 'Token after a trailing “.” boundary';
}

/// `\` was not followed by a digit.
class ExpectedDigitAfterBackslash extends CompileErrorKind {
  /// Creates a missing-digit error.
  const ExpectedDigitAfterBackslash();

  @override
  String toString() => 'Expected a digit after “\\”';
}

/// A `base\min` weight used a minimum higher than the base priority.
class IncreasingPriority extends CompileErrorKind {
  /// Creates an error when [min] is greater than [base].
  const IncreasingPriority({required this.base, required this.min});

  /// The base priority digit.
  final int base;

  /// The minimum priority after `\`.
  final int min;

  @override
  String toString() => 'Priority must not increase ($base\\$min)';
}

/// `\` appeared without a preceding priority digit.
class BackslashWithoutDigit extends CompileErrorKind {
  /// Creates a stray-backslash error.
  const BackslashWithoutDigit();

  @override
  String toString() => '“\\” must follow a priority digit';
}

/// `^` was not followed by `{`, `@`, or `=`.
class CaretNotFollowed extends CompileErrorKind {
  /// Creates a caret-syntax error.
  const CaretNotFollowed();

  @override
  String toString() => '“^” must be followed by “{”, “@”, or “=”';
}

/// `@` or `=` was not followed by a group name.
class EmptyGroupName extends CompileErrorKind {
  /// Creates an empty-group-name error.
  const EmptyGroupName();

  @override
  String toString() => 'Empty group name';
}

/// A pattern line contained no joining letters.
class NoLetters extends CompileErrorKind {
  /// Creates a no-letters error.
  const NoLetters();

  @override
  String toString() => 'Pattern has no letters';
}

/// An unexpected character appeared in the pattern.
class StrayCharacter extends CompileErrorKind {
  /// Creates an error for [character].
  const StrayCharacter(this.character);

  /// The unexpected code point.
  final int character;

  @override
  String toString() => "Stray character '${String.fromCharCode(character)}'";
}

/// Two weights were assigned to the same connection.
class ConflictingWeights extends CompileErrorKind {
  /// Creates a conflicting-weights error.
  const ConflictingWeights();

  @override
  String toString() => 'Conflicting weights at one connection';
}

/// A weight was placed on a `.` boundary rather than inside the run.
class WeightOutsideRun extends CompileErrorKind {
  /// Creates a weight-outside-run error.
  const WeightOutsideRun();

  @override
  String toString() => 'Weight outside the run at a “.” boundary';
}

/// A `use` line named an unknown built-in pattern set.
class UnknownImport extends CompileErrorKind {
  /// Creates an error for [name].
  const UnknownImport(this.name);

  /// The unknown set name.
  final String name;

  @override
  String toString() => 'Unknown pattern set “$name”';
}
