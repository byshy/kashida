## 0.0.2

* Insert tatweel with `insertKashida` and `insertKashidaAt`, or `KashidaAnalysis.insert` (same count at every point — not justification).
* `findKashidaPoints` now returns `KashidaAnalysis` and takes a named `removeExistingKashida`.
* Wrap and fill lines with `layoutParagraph` / `layoutParagraphStyled` / `KashidaText`.
* Newlines start a new paragraph; leftover width is `KashidaLine.unusedWidth`.
* Infer Syriac fill from the `syriac` builtin; `KashidaPoint.endOffsetIn` for string offsets.
* Add `requiredBuiltinPatternSet`, `findKashidaPointsIn`, and export `kashida` / `kashidaCodepoint`.

## 0.0.1

* Initial Dart/Flutter port of [raqim-kashida](https://github.com/aliftype/raqim-kashida).
* Compile kashida pattern text (`compilePatternText`) and look up built-in sets (`arabic-naskh`, `arabic-nastaliq`, `arabic-simple`, `syriac`).
* Find insertion points and priorities with `findKashidaPoints` and `findKashidaPointsPatterns`.
* Include an example app that justifies a paragraph from those points.
