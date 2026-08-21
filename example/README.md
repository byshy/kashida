# Kashida example

A Flutter app that uses the `kashida` package to find tatweel insertion points,
then justifies a paragraph to a pixel width.

The package finds points, can insert a fixed number of tatweels, or can wrap
and fill a line. This example uses `KashidaText`: measure with the selected
font, insert U+0640 by priority, and put leftover pixels between words.

## Run

From the package root:

```sh
cd example
flutter run
```

## What you can try

- Edit the sample Arabic paragraph
- Switch built-in pattern sets (`arabic-naskh`, `arabic-nastaliq`,
  `arabic-simple`, `syriac`)
- Switch fonts (Naskh, Amiri, Kufi, Nastaliq, Syriac, and others). Layout
  measures and paints with the selected face; pick a matching pattern set
  (the UI shows a suggestion)
- Change font size and paragraph width
- Cap min/max kashidas per connection
- Toggle justification and kashida insertion independently

`lib/justify.dart` holds wrapping and elongation. `lib/main.dart` is the UI.
