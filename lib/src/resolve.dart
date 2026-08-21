import 'grapheme.dart';
import 'kashida_core.dart';
import 'pattern.dart';
import 'rasm.dart';
import 'unicode/joining.dart';

bool _matchToken(Token token, List<Grapheme> graphemes, int index) {
  final g = graphemes[index];
  return switch (token) {
    AnyToken() => isJoiningType(g.joiningType),
    LiteralToken(:final codepoint) => g.baseCodepoint == codepoint,
    GroupToken(:final group) =>
      rasmMatches(group, g.joiningGroup, formOf(graphemes, index)),
    ExactGroupToken(:final group) => g.joiningGroup == group,
    GroupSetToken(:final members) =>
      members.any((m) => _matchToken(m, graphemes, index)),
    NotGroupSetToken(:final members) =>
      isJoiningType(g.joiningType) &&
          !members.any((m) => _matchToken(m, graphemes, index)),
  };
}

bool _guardMatches(LengthGuard? guard, int len) {
  return switch (guard) {
    null => true,
    ExactLength(:final n) => len == n,
    MinLength(:final n) => len >= n,
    RangeLength(:final lo, :final hi) => len >= lo && len <= hi,
    OpenLength() => true,
  };
}

int _guardFloor(LengthGuard? guard) {
  return switch (guard) {
    null => 2,
    RangeLength(:final lo) => lo,
    ExactLength(:final n) || MinLength(:final n) || OpenLength(:final n) => n,
  };
}

int _effectivePriority(int base, int min, int len, int floor) {
  final value = base - (len - floor).abs();
  return value > min ? value : min;
}

List<KashidaPoint> resolveRun(
  List<Grapheme> graphemes,
  List<int> run,
  PatternSet set,
) {
  final len = run.length;
  if (len < 2) {
    return const [];
  }

  final priorities = List<int?>.filled(len - 1, null);

  for (final pattern in set.patterns) {
    if (!_guardMatches(pattern.guard, len)) {
      continue;
    }
    final floor = _guardFloor(pattern.guard);
    final m = pattern.tokens.length;
    if (m > len) {
      continue;
    }
    for (var start = 0; start <= len - m; start++) {
      if (pattern.leadingBoundary && start != 0) {
        continue;
      }
      if (pattern.trailingBoundary &&
          (start + m != len ||
              graphemes[run[len - 1]].joiningType == JoiningType.joinCausing)) {
        continue;
      }
      var matched = true;
      for (var k = 0; k < m; k++) {
        if (!_matchToken(pattern.tokens[k], graphemes, run[start + k])) {
          matched = false;
          break;
        }
      }
      if (!matched) {
        continue;
      }

      for (var gap = 0; gap <= m; gap++) {
        final weight = pattern.weights[gap];
        if (weight == null) {
          continue;
        }
        final point = start + gap - 1;
        if (point < 0 || point > len - 2) {
          continue;
        }
        priorities[point] = switch (weight) {
          SuppressWeight() => null,
          PriorityWeight(:final base, :final min) =>
            _effectivePriority(base, min, len, floor),
        };
      }
    }
  }

  final out = <KashidaPoint>[];
  for (var point = 0; point < len - 1; point++) {
    final priority = priorities[point];
    if (priority == null) {
      continue;
    }
    var index = run[point];
    while (index + 1 < graphemes.length && graphemes[index + 1].isMarkSeat) {
      index += 1;
    }
    out.add(KashidaPoint(index: index, priority: priority));
  }
  return out;
}
