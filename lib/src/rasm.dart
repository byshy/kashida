import 'error.dart';
import 'grapheme.dart';
import 'unicode/joining.dart';

class RasmClass {
  const RasmClass(this.groups, this.forms);
  final List<JoiningGroup> groups;
  final List<JoiningForm> forms;
}

const rasmClasses = <RasmClass>[
  RasmClass(
    [
      JoiningGroup.beh,
      JoiningGroup.noon,
      JoiningGroup.africanNoon,
      JoiningGroup.nya,
      JoiningGroup.yeh,
      JoiningGroup.farsiYeh,
    ],
    [JoiningForm.initial, JoiningForm.medial],
  ),
  RasmClass(
    [
      JoiningGroup.feh,
      JoiningGroup.africanFeh,
      JoiningGroup.qaf,
      JoiningGroup.africanQaf,
    ],
    [JoiningForm.initial, JoiningForm.medial],
  ),
  RasmClass(
    [JoiningGroup.feh, JoiningGroup.africanFeh],
    [JoiningForm.finalForm, JoiningForm.isolated],
  ),
  RasmClass(
    [JoiningGroup.qaf, JoiningGroup.africanQaf],
    [JoiningForm.finalForm, JoiningForm.isolated],
  ),
  RasmClass(
    [
      JoiningGroup.heh,
      JoiningGroup.hehGoal,
      JoiningGroup.tehMarbuta,
      JoiningGroup.tehMarbutaGoal,
    ],
    [JoiningForm.finalForm, JoiningForm.isolated],
  ),
  RasmClass(
    [JoiningGroup.noon, JoiningGroup.africanNoon, JoiningGroup.nya],
    [JoiningForm.finalForm, JoiningForm.isolated],
  ),
  RasmClass(
    [JoiningGroup.yeh, JoiningGroup.farsiYeh, JoiningGroup.yehWithTail],
    [JoiningForm.finalForm, JoiningForm.isolated],
  ),
  RasmClass(
    [JoiningGroup.yehBarree, JoiningGroup.burushaskiYehBarree],
    [JoiningForm.finalForm, JoiningForm.isolated],
  ),
  RasmClass(
    [JoiningGroup.kaf, JoiningGroup.gaf],
    [JoiningForm.initial, JoiningForm.medial],
  ),
];

bool rasmMatches(
  JoiningGroup tokenGroup,
  JoiningGroup graphemeGroup,
  JoiningForm form,
) {
  for (final cls in rasmClasses) {
    if (!cls.forms.contains(form) || !cls.groups.contains(tokenGroup)) {
      continue;
    }
    return cls.groups.first == tokenGroup && cls.groups.contains(graphemeGroup);
  }
  return tokenGroup == graphemeGroup;
}

JoiningGroup resolveGroupName(String name) {
  final unknown = UnknownGroupName(name);
  if (name.isEmpty || (name.codeUnitAt(0) != 0x40 && name.codeUnitAt(0) != 0x3D)) {
    throw unknown;
  }
  final bare = name.substring(1);
  final group = joiningGroupLongNames[bare];
  if (group == null || group == JoiningGroup.noJoiningGroup) {
    throw unknown;
  }
  return group;
}
