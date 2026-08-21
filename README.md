# kashida

A Dart port of [raqim-kashida](https://github.com/aliftype/raqim-kashida): find
_kashida_ (_tatweel_, U+0640) insertion points and priorities in Arabic and
Syriac text, driven by a small pattern language.

Given a string and a compiled pattern set, the package finds connections
that may take a kashida and a priority from 0–9 (higher is better). Detection
is based on text analysis and kashida rules. It does **not** take fonts or
shaping into account. Use `insertKashida` to splice tatweel, or
`layoutParagraph` with your own `measure` function to wrap and fill a line.

For background, see Khaled Hosny’s
[introduction to raqim-kashida](https://aliftype.com/blog/introducing-raqim-kashida/english)
and the
[interactive demo](https://aliftype.com/raqim-kashida/english/).

## Features

- Compile pattern text, including `use` of a built-in set
- Built-in sets: `arabic-naskh`, `arabic-nastaliq`, `arabic-simple`, `syriac`
- Optional stripping of bare tatweels (mark-seated tatweels are kept)
- Insert tatweel into a string (`insertKashida`) without choosing a font
- Wrap and fill lines given a width and a `measure` callback
- Grapheme-cluster indices, joining analysis, and rasm folding matching the
  original library
- A Flutter example that justifies a paragraph from those points

## Getting started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  kashida: ^0.0.2
```

Then:

```dart
import 'package:kashida/kashida.dart';
```

## Usage

```dart
import 'package:kashida/kashida.dart';

void main() {
  final set = requiredBuiltinPatternSet('arabic-simple');

  // Points only
  final found = findKashidaPoints('بيت', set);
  for (final point in found.points) {
    print('${point.priority} @ ${point.index}');
  }

  // Original text in, elongated string out
  print(insertKashida('بيت', set)); // بيت with tatweel at the chosen points
}
```

`findKashidaPointsPatterns` skips stripping and returns points only.

To wrap a paragraph to a width, pass a `measure` callback in the same units
as `width` (for example `TextPainter` in Flutter):

```dart
final lines = layoutParagraph(
  text,
  set,
  width: 320,
  measure: (line) => /* your glyph width for line */,
);
```

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
`requiredBuiltinPatternSet(name)` throws if the name is unknown.

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
use it in your own typesetting code. Insertion is U+0640; filling a pixel
width still needs a font-aware `measure` function.
