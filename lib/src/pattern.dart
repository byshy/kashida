import 'builtin.dart';
import 'error.dart';
import 'grapheme.dart';
import 'rasm.dart';
import 'unicode/joining.dart';

sealed class Token {
  const Token();
}

class GroupToken extends Token {
  const GroupToken(this.group);
  final JoiningGroup group;
}

class ExactGroupToken extends Token {
  const ExactGroupToken(this.group);
  final JoiningGroup group;
}

class GroupSetToken extends Token {
  const GroupSetToken(this.members);
  final List<Token> members;
}

class NotGroupSetToken extends Token {
  const NotGroupSetToken(this.members);
  final List<Token> members;
}

class LiteralToken extends Token {
  const LiteralToken(this.codepoint);
  final int codepoint;
}

class AnyToken extends Token {
  const AnyToken();
}

sealed class Weight {
  const Weight();
}

class PriorityWeight extends Weight {
  const PriorityWeight({required this.base, required this.min});
  final int base;
  final int min;
}

class SuppressWeight extends Weight {
  const SuppressWeight();
}

sealed class LengthGuard {
  const LengthGuard();
}

class ExactLength extends LengthGuard {
  const ExactLength(this.n);
  final int n;
}

class MinLength extends LengthGuard {
  const MinLength(this.n);
  final int n;
}

class RangeLength extends LengthGuard {
  const RangeLength({required this.lo, required this.hi});
  final int lo;
  final int hi;
}

class OpenLength extends LengthGuard {
  const OpenLength(this.n);
  final int n;
}

class CompiledPattern {
  const CompiledPattern({
    required this.guard,
    required this.tokens,
    required this.weights,
    required this.leadingBoundary,
    required this.trailingBoundary,
  });

  final LengthGuard? guard;
  final List<Token> tokens;
  final List<Weight?> weights;
  final bool leadingBoundary;
  final bool trailingBoundary;
}

/// A compiled set of kashida insertion patterns.
class PatternSet {
  const PatternSet(this.patterns);
  final List<CompiledPattern> patterns;
}

String _stripComment(String raw) {
  final hash = raw.indexOf('#');
  final body = hash == -1 ? raw : raw.substring(0, hash);
  return body.trim();
}

bool _isLetter(int ch) => isJoiningType(joiningTypeOf(ch));

Token resolveReference(String name) {
  if (name == '@Tatweel' || name == '=Tatweel') {
    return const LiteralToken(kashidaCodepoint);
  }
  final group = resolveGroupName(name);
  if (name.startsWith('@')) {
    return GroupToken(group);
  }
  return ExactGroupToken(group);
}

void _setWeight(List<Weight?> weights, int k, Weight weight) {
  while (weights.length <= k) {
    weights.add(null);
  }
  if (weights[k] != null) {
    throw const ConflictingWeights();
  }
  weights[k] = weight;
}

class _Parser {
  _Parser(this.chars);
  final List<int> chars;
  int pos = 0;

  int? peek() => pos < chars.length ? chars[pos] : null;

  bool eat(int expected) {
    if (peek() == expected) {
      pos += 1;
      return true;
    }
    return false;
  }

  int? digit() {
    final ch = peek();
    if (ch == null || ch < 0x30 || ch > 0x39) {
      return null;
    }
    pos += 1;
    return ch - 0x30;
  }

  void skipWhitespace() {
    while (peek() == 0x20 || peek() == 0x09) {
      pos += 1;
    }
  }

  CompiledPattern pattern() {
    final LengthGuard? guard = peek() == 0x5B ? this.guard() : null;

    final tokens = <Token>[];
    final weights = <Weight?>[];
    var leadingBoundary = false;
    var trailingBoundary = false;

    while (true) {
      skipWhitespace();
      final ch = peek();
      if (ch == null) {
        break;
      }
      if (ch == 0x2E) {
        pos += 1;
        if (tokens.isEmpty) {
          leadingBoundary = true;
        } else {
          trailingBoundary = true;
        }
        continue;
      }
      if (trailingBoundary) {
        throw const TokenAfterTrailingBoundary();
      }
      if ((ch >= 0x30 && ch <= 0x39) || ch == 0x21 || ch == 0x5C) {
        _setWeight(weights, tokens.length, weight());
        continue;
      }
      tokens.add(token(ch));
    }

    if (tokens.isEmpty) {
      throw const NoLetters();
    }
    while (weights.length < tokens.length + 1) {
      weights.add(null);
    }
    if ((leadingBoundary && weights[0] != null) ||
        (trailingBoundary && weights[tokens.length] != null)) {
      throw const WeightOutsideRun();
    }
    return CompiledPattern(
      guard: guard,
      tokens: tokens,
      weights: weights,
      leadingBoundary: leadingBoundary,
      trailingBoundary: trailingBoundary,
    );
  }

  LengthGuard guard() {
    pos += 1;
    final start = pos;
    while (peek() != null && peek() != 0x5D) {
      pos += 1;
    }
    if (!eat(0x5D)) {
      throw const UnterminatedLengthGuard();
    }
    final body = String.fromCharCodes(chars.sublist(start, pos - 1));
    final trimmed = body.trim();
    Never invalid() => throw InvalidLengthGuard(body);

    int bound(String s) {
      if (s.isEmpty || !RegExp(r'^[0-9]+$').hasMatch(s)) {
        invalid();
      }
      return int.parse(s);
    }

    final LengthGuard guard;
    if (trimmed.startsWith(':') && trimmed.endsWith(':') && trimmed.length >= 2) {
      guard = OpenLength(bound(trimmed.substring(1, trimmed.length - 1)));
    } else if (trimmed.endsWith(':')) {
      guard = MinLength(bound(trimmed.substring(0, trimmed.length - 1)));
    } else if (trimmed.contains(':')) {
      final colon = trimmed.indexOf(':');
      guard = RangeLength(
        lo: bound(trimmed.substring(0, colon)),
        hi: bound(trimmed.substring(colon + 1)),
      );
    } else {
      guard = ExactLength(bound(trimmed));
    }

    final boundsOk = switch (guard) {
      ExactLength(:final n) || MinLength(:final n) || OpenLength(:final n) =>
        n >= 2,
      RangeLength(:final lo, :final hi) => lo >= 2 && lo <= hi,
    };
    if (boundsOk) {
      return guard;
    }
    invalid();
  }

  Weight weight() {
    if (eat(0x21)) {
      return const SuppressWeight();
    }
    final base = digit();
    if (base == null) {
      throw const BackslashWithoutDigit();
    }
    var min = base;
    if (eat(0x5C)) {
      final end = digit();
      if (end == null) {
        throw const ExpectedDigitAfterBackslash();
      }
      min = end;
      if (min > base) {
        throw IncreasingPriority(base: base, min: min);
      }
    }
    return PriorityWeight(base: base, min: min);
  }

  Token token(int ch) {
    switch (ch) {
      case 0x2A:
        pos += 1;
        return const AnyToken();
      case 0x7B:
        return GroupSetToken(set());
      case 0x5E:
        pos += 1;
        final next = peek();
        if (next == 0x7B) {
          return NotGroupSetToken(set());
        }
        if (next == 0x40 || next == 0x3D) {
          return NotGroupSetToken([reference()]);
        }
        throw const CaretNotFollowed();
      case 0x40:
      case 0x3D:
        return reference();
      default:
        pos += 1;
        if (_isLetter(ch)) {
          return LiteralToken(ch);
        }
        throw StrayCharacter(ch);
    }
  }

  List<Token> set() {
    pos += 1;
    final start = pos;
    while (peek() != null && peek() != 0x7D) {
      pos += 1;
    }
    if (!eat(0x7D)) {
      throw const UnterminatedGroupSet();
    }
    final body = String.fromCharCodes(chars.sublist(start, pos - 1));
    if (body.trim().isEmpty) {
      throw const EmptyGroupSet();
    }
    final members = <Token>[];
    for (final part in body.split(RegExp(r'\s+'))) {
      if (part.isEmpty) {
        continue;
      }
      if (part.startsWith('@') || part.startsWith('=')) {
        members.add(resolveReference(part));
      } else {
        for (final ch in part.runes) {
          if (_isLetter(ch)) {
            members.add(LiteralToken(ch));
          } else {
            throw StrayCharacter(ch);
          }
        }
      }
    }
    return members;
  }

  Token reference() {
    final name = StringBuffer()..writeCharCode(chars[pos]);
    pos += 1;
    while (true) {
      final c = peek();
      if (c == null) {
        break;
      }
      final isNameChar =
          (c >= 0x41 && c <= 0x5A) ||
          (c >= 0x61 && c <= 0x7A) ||
          c == 0x5F;
      if (!isNameChar) {
        break;
      }
      name.writeCharCode(c);
      pos += 1;
    }
    if (name.length == 1) {
      throw const EmptyGroupName();
    }
    return resolveReference(name.toString());
  }
}

CompiledPattern? _parseLine(String raw) {
  final line = _stripComment(raw);
  if (line.isEmpty) {
    return null;
  }
  return _Parser(line.runes.toList()).pattern();
}

String? _parseUse(String line) {
  if (!line.startsWith('use')) {
    return null;
  }
  final rest = line.substring(3);
  if (rest.startsWith(' ') || rest.startsWith('\t')) {
    return rest.trim();
  }
  return null;
}

/// Compiles pattern text into a [PatternSet].
PatternSet compilePatternText(String text) {
  final patterns = <CompiledPattern>[];
  final lines = text.split('\n');
  for (var index = 0; index < lines.length; index++) {
    var raw = lines[index];
    if (raw.endsWith('\r')) {
      raw = raw.substring(0, raw.length - 1);
    }
    CompileError context(CompileErrorKind kind) =>
        CompileError(kind: kind, lineNumber: index + 1);
    try {
      final importedName = _parseUse(_stripComment(raw));
      if (importedName != null) {
        final imported = builtinPatternSet(importedName);
        if (imported == null) {
          throw context(UnknownImport(importedName));
        }
        patterns.addAll(imported.patterns);
        continue;
      }
      final pattern = _parseLine(raw);
      if (pattern != null) {
        patterns.add(pattern);
      }
    } on CompileError {
      rethrow;
    } on CompileErrorKind catch (kind) {
      throw context(kind);
    }
  }
  return PatternSet(patterns);
}
