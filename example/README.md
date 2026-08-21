# Kashida example

A Flutter app that uses every public entry point of the `kashida` package.
A screen capture of the Justify tab is on the [package README](../README.md).

## Run

From the package root:

```sh
cd example
flutter run
```

Fonts are bundled under `fonts/` (OFL). They load on macOS, iOS, Android, and
web without downloading Google Fonts at runtime.

## Tabs

- **Justify** — `KashidaText` wraps and fills a pixel width. Last line of
  each paragraph stays short unless **Justify last line** is on. Leftover
  space thinner than a tatweel is reported as `unusedWidth`.
- **Find & insert** — same points, three operations: find
  (`findKashidaPoints`), stamp every join (`insertKashida`), or fill a width
  (`layoutParagraph`).
- **Rules** — live `compilePatternText`, including `use` of a built-in set
  and `CompileError` when a line is invalid.

Switching to the Syriac pattern (or Noto Sans Syriac) loads a Syriac sample.
