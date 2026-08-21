## 0.0.2

* Insert tatweel with `insertKashida` and `insertKashidaAt`, or `KashidaAnalysis.insert`.
* `findKashidaPoints` now returns `KashidaAnalysis` and takes a named `removeExistingKashida`.
* Wrap and fill lines with `layoutParagraph` via a `measure` callback (no font coupling).
* Add `requiredBuiltinPatternSet`, export `kashida` / `kashidaCodepoint`, and `CompiledPattern`.

## 0.0.1

* Initial Dart/Flutter port of [raqim-kashida](https://github.com/aliftype/raqim-kashida).
* Compile kashida pattern text (`compilePatternText`) and look up built-in sets (`arabic-naskh`, `arabic-nastaliq`, `arabic-simple`, `syriac`).
* Find insertion points and priorities with `findKashidaPoints` and `findKashidaPointsPatterns`.
* Include an example app that justifies a paragraph from those points.
