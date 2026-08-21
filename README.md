# kashida

A Dart port of [raqim-kashida](https://github.com/aliftype/raqim-kashida): find
_kashida_ (_tatweel_, U+0640) insertion points and priorities in Arabic and
Syriac text, driven by a small pattern language.

Given a string and a compiled pattern set, the package returns the connections
that may take a kashida and a priority from 0–9 (higher is better). Detection
is based on text analysis and kashida rules. It does **not** take fonts or
shaping into account, and it does **not** justify lines. Callers insert tatweel
(and optional word spacing) using the returned points.

For background, see Khaled Hosny’s
[introduction to raqim-kashida](https://aliftype.com/blog/introducing-raqim-kashida/english)
and the
[interactive demo](https://aliftype.com/raqim-kashida/english/).

## Features

- Compile pattern text, including `use` of a built-in set
- Built-in sets: `arabic-naskh`, `arabic-nastaliq`, `arabic-simple`, `syriac`
- Optional stripping of bare tatweels (mark-seated tatweels are kept)
- Grapheme-cluster indices, joining analysis, and rasm folding matching the
  original library
- A Flutter example that justifies a paragraph from those points

## Getting started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  kashida: ^0.0.1
```

Then:

```dart
import 'package:kashida/kashida.dart';
```

## Usage

```dart
import 'package:kashida/kashida.dart';

void main() {
  final set = builtinPatternSet('arabic-simple')!;
  final (cleaned, points) = findKashidaPoints('بيت', set, true);

  for (final point in points) {
    // Insert a tatweel after grapheme cluster `point.index` in `cleaned`.
    print('${point.priority} @ ${point.index}');
  }
}
```

`findKashidaPointsPatterns` skips stripping and returns points only.

Custom rules can extend or override a built-in set:

```dart
final set = compilePatternText('''
use arabic-naskh
* 2 @Heh .
''');
```

The pattern language is the same as upstream. See the
[raqim-kashida README](https://github.com/aliftype/raqim-kashida#pattern-sets)
for the grammar, length guards, priorities, and `!` suppression.

### Built-in pattern sets

| Name | Intended for |
| --- | --- |
| `arabic-naskh` | Classical naskh and naskh-like faces |
| `arabic-nastaliq` | Nastaliq (naskh rules plus nastaliq tailoring) |
| `arabic-simple` | Simple / kufic-style faces (Microsoft-style newspaper rules) |
| `syriac` | Syriac, following the LibreOffice / expert guidelines |

`builtinPatternSetNames()` and `isBuiltinPatternSet(name)` list and check them.

### Example app

The `example/` app wraps text to a pixel width, inserts tatweel at the
highest-priority points, and uses leftover space between words. Run:

```sh
cd example
flutter run
```

## Acknowledgements

This package is a Dart/Flutter port of
[raqim-kashida](https://github.com/aliftype/raqim-kashida) by
[Khaled Hosny](https://github.com/khaledhosny) and
[Alif Type](https://aliftype.com/).

Thank you to Khaled and everyone behind raqim-kashida for the research, the
pattern language, the built-in rule sets, and the tests this port follows.
Any mistakes in the Dart implementation are ours.

## Additional information

Issues and contributions are welcome on the package repository. Please include
a small Arabic or Syriac sample and the pattern set name when reporting
justification or matching bugs.

The original crate is MIT-licensed. This port keeps the same spirit: you may
use it in your own typesetting code; you still need a font and a layout pass
to actually stretch the line.
