import 'package:characters/characters.dart';

import 'unicode/joining.dart';

const kashida = '\u{0640}';
const kashidaCodepoint = 0x0640;

class Grapheme {
  const Grapheme({
    required this.baseCodepoint,
    required this.joiningGroup,
    required this.joiningType,
    required this.isMarkSeat,
  });

  final int baseCodepoint;
  final JoiningGroup joiningGroup;
  final JoiningType joiningType;
  final bool isMarkSeat;
}

enum JoiningForm { isolated, initial, medial, finalForm }

bool isBareTatweelAt(List<int> chars, int k) {
  if (chars[k] != kashidaCodepoint) {
    return false;
  }
  if (k + 1 >= chars.length) {
    return true;
  }
  return joiningTypeOf(chars[k + 1]) != JoiningType.transparent;
}

List<Grapheme> splitGraphemes(String text) {
  final out = <Grapheme>[];
  for (final cluster in text.characters) {
    final units = cluster.runes.toList();
    final base = units.first;
    var joiningType = joiningTypeOf(base);
    final rest = units.skip(1);
    if (rest.any((c) => joiningTypeOf(c) == JoiningType.nonJoining)) {
      joiningType = switch (joiningType) {
        JoiningType.dualJoining || JoiningType.joinCausing =>
          JoiningType.rightJoining,
        JoiningType.leftJoining || JoiningType.transparent =>
          JoiningType.nonJoining,
        _ => joiningType,
      };
    } else if (joiningType == JoiningType.dualJoining &&
        rest.any((c) => joiningTypeOf(c) == JoiningType.joinCausing)) {
      joiningType = JoiningType.joinCausing;
    }
    out.add(
      Grapheme(
        baseCodepoint: base,
        joiningGroup: joiningGroupOf(base),
        joiningType: joiningType,
        isMarkSeat:
            base == kashidaCodepoint &&
            units.any((c) => joiningTypeOf(c) == JoiningType.transparent),
      ),
    );
  }
  return out;
}

bool isJoiningType(JoiningType joiningType) {
  return joiningType == JoiningType.dualJoining ||
      joiningType == JoiningType.rightJoining ||
      joiningType == JoiningType.leftJoining ||
      joiningType == JoiningType.joinCausing;
}

bool joinsLeft(List<Grapheme> graphemes, int index) {
  final cur = graphemes[index];
  if (!isJoiningType(cur.joiningType) ||
      cur.joiningType == JoiningType.rightJoining) {
    return false;
  }
  if (index + 1 >= graphemes.length) {
    return false;
  }
  final next = graphemes[index + 1];
  return isJoiningType(next.joiningType) &&
      next.joiningType != JoiningType.leftJoining;
}

bool joinsRight(List<Grapheme> graphemes, int index) {
  final cur = graphemes[index];
  if (!isJoiningType(cur.joiningType) ||
      cur.joiningType == JoiningType.leftJoining) {
    return false;
  }
  if (index == 0) {
    return false;
  }
  final prev = graphemes[index - 1];
  if (!isJoiningType(prev.joiningType)) {
    return false;
  }
  return prev.joiningType != JoiningType.rightJoining;
}

JoiningForm formOf(List<Grapheme> graphemes, int index) {
  final right = joinsRight(graphemes, index);
  final left = joinsLeft(graphemes, index);
  if (right && left) {
    return JoiningForm.medial;
  }
  if (!right && left) {
    return JoiningForm.initial;
  }
  if (right && !left) {
    return JoiningForm.finalForm;
  }
  return JoiningForm.isolated;
}

List<List<int>> joinedRuns(List<Grapheme> graphemes) {
  final out = <List<int>>[];
  var current = <int>[];
  for (var i = 0; i < graphemes.length; i++) {
    final g = graphemes[i];
    if (g.joiningType == JoiningType.transparent || g.isMarkSeat) {
      continue;
    }
    if (!isJoiningType(g.joiningType)) {
      if (current.isNotEmpty) {
        out.add(current);
        current = <int>[];
      }
      continue;
    }
    if (current.isNotEmpty) {
      final prev = graphemes[current.last];
      final prevJoinsForward = prev.joiningType != JoiningType.rightJoining;
      final curJoinsBackward = g.joiningType != JoiningType.leftJoining;
      if (!prevJoinsForward || !curJoinsBackward) {
        out.add(current);
        current = <int>[];
      }
    }
    current.add(i);
  }
  if (current.isNotEmpty) {
    out.add(current);
  }
  return out;
}
