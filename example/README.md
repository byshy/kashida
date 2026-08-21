# Kashida example

A Flutter app that uses the `kashida` package to find tatweel insertion points,
then justifies a paragraph to a pixel width.

The package only reports **where** kashida may go and at what **priority**. This
example is the layout pass: wrap lines, insert U+0640 at the best points, and
spread leftover space between words.

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
