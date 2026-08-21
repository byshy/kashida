import 'package:flutter/material.dart';
import 'package:kashida/kashida.dart';
import 'package:kashida_example/demo_fonts.dart';
import 'package:kashida_example/demo_state.dart';
import 'package:kashida_example/justify.dart' hide layoutParagraph;
import 'package:kashida_example/widgets.dart';

class JustifyPage extends StatelessWidget {
  const JustifyPage({super.key, required this.controller});

  final DemoController controller;

  @override
  Widget build(BuildContext context) {
    final demo = controller;
    final set = demo.builtinSet;
    final scaler = MediaQuery.textScalerOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        const listPadding = 16.0;
        const boxPadding = 12.0;
        final availableWidth =
            constraints.maxWidth - listPadding * 2 - boxPadding * 2;
        final paragraphWidth = clampParagraphWidth(
          demo.paragraphWidth,
          availableWidth,
        );
        final widthCapped = paragraphWidth < demo.paragraphWidth;
        final lines = layoutParagraphStyled(
          demo.text,
          set,
          demo.textStyle,
          width: paragraphWidth,
          textScaler: scaler,
          minKashidas: demo.minKashidas.round(),
          maxKashidas: demo.maxKashidas.round(),
          justified: demo.justify,
          justifyLastLine: demo.justifyLastLine,
          applyKashida: demo.applyKashida,
          removeExistingKashida: demo.removeExistingKashida,
          fill: demo.fillStyle,
        );
        final leftover = lines
            .where((line) => line.stretch)
            .map(
              (line) => line.unusedWidth(
                paragraphWidth,
                (value) =>
                    measureTextWidth(value, demo.textStyle, textScaler: scaler),
              ),
            )
            .toList();

        return ListView(
          padding: const EdgeInsets.all(listPadding),
          children: [
            TextField(
              controller: demo.controller,
              minLines: 3,
              maxLines: 8,
              textDirection: TextDirection.rtl,
              style: demo.textStyle,
              onChanged: (_) => demo.onTextChanged(),
              decoration: const InputDecoration(
                labelText: 'Text',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                DropdownMenu<String>(
                  key: ValueKey('font-${demo.fontId}'),
                  initialSelection: demo.fontId,
                  label: const Text('Font'),
                  dropdownMenuEntries: [
                    for (final font in demoFonts)
                      DropdownMenuEntry(value: font.id, label: font.label),
                  ],
                  onSelected: (value) {
                    if (value != null) {
                      demo.setFontId(value);
                    }
                  },
                ),
                DropdownMenu<String>(
                  key: ValueKey('pattern-${demo.patternName}'),
                  initialSelection: demo.patternName,
                  label: const Text('Pattern set'),
                  helperText: 'Suggested: ${demo.font.suggestedPattern}',
                  dropdownMenuEntries: [
                    for (final name in builtinPatternSetNames())
                      DropdownMenuEntry(value: name, label: name),
                  ],
                  onSelected: (value) {
                    if (value != null) {
                      demo.setPatternName(value);
                    }
                  },
                ),
                DropdownMenu<String>(
                  key: ValueKey('fill-${demo.fillOverride}-${demo.fillStyle}'),
                  initialSelection: demo.fillOverride == null
                      ? 'auto'
                      : demo.fillOverride!.name,
                  label: const Text('Fill'),
                  helperText: demo.fillOverride == null
                      ? 'fillStyleFor(${set.id}) → ${demo.fillStyle.name}'
                      : 'override ${demo.fillStyle.name}',
                  dropdownMenuEntries: const [
                    DropdownMenuEntry(value: 'auto', label: 'Auto from set'),
                    DropdownMenuEntry(value: 'arabic', label: 'Arabic'),
                    DropdownMenuEntry(value: 'syriac', label: 'Syriac'),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'arabic':
                        demo.setFillOverride(KashidaFillStyle.arabic);
                      case 'syriac':
                        demo.setFillOverride(KashidaFillStyle.syriac);
                      default:
                        demo.setFillOverride(null);
                    }
                  },
                ),
                FilterChip(
                  label: const Text('Justify'),
                  selected: demo.justify,
                  onSelected: demo.setJustify,
                ),
                FilterChip(
                  label: const Text('Justify last line'),
                  selected: demo.justifyLastLine,
                  onSelected: demo.justify ? demo.setJustifyLastLine : null,
                ),
                FilterChip(
                  label: const Text('Apply kashida'),
                  selected: demo.applyKashida,
                  onSelected: demo.justify ? demo.setApplyKashida : null,
                ),
                FilterChip(
                  label: const Text('Strip existing tatweel'),
                  selected: demo.removeExistingKashida,
                  onSelected: demo.setRemoveExistingKashida,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Size: ${demo.fontSize.round()}px'),
            Slider(
              min: 16,
              max: 48,
              divisions: 32,
              value: demo.fontSize,
              onChanged: demo.setFontSize,
            ),
            Text(
              widthCapped
                  ? 'Paragraph width: ${paragraphWidth.round()}px '
                        '(capped from ${demo.paragraphWidth.round()}px)'
                  : 'Paragraph width: ${demo.paragraphWidth.round()}px',
            ),
            Slider(
              min: 280,
              max: 800,
              divisions: 52,
              value: demo.paragraphWidth,
              onChanged: demo.setParagraphWidth,
            ),
            Text('Min kashidas per point: ${demo.minKashidas.round()}'),
            Slider(
              min: 1,
              max: 6,
              divisions: 5,
              value: demo.minKashidas,
              onChanged: demo.setMinKashidas,
            ),
            Text('Max kashidas per point: ${demo.maxKashidas.round()}'),
            Slider(
              min: 1,
              max: 8,
              divisions: 7,
              value: demo.maxKashidas,
              onChanged: demo.setMaxKashidas,
            ),
            const SizedBox(height: 8),
            DemoSection(
              title: !demo.justify
                  ? 'KashidaText, unjustified'
                  : demo.justifyLastLine
                  ? 'KashidaText (every line stretched, including the last)'
                  : 'KashidaText (last line of each paragraph left short)',
              subtitle:
                  'layoutParagraphStyled + unusedWidth leftover on stretched lines: '
                  '${leftover.isEmpty ? 'none' : leftover.map((w) => '${w.toStringAsFixed(1)}px').join(', ')}',
              child: ParagraphFrame(
                width: paragraphWidth,
                child: KashidaText(
                  demo.text,
                  patternSet: set,
                  width: paragraphWidth,
                  style: demo.textStyle,
                  textScaler: scaler,
                  minKashidas: demo.minKashidas.round(),
                  maxKashidas: demo.maxKashidas.round(),
                  justified: demo.justify,
                  justifyLastLine: demo.justifyLastLine,
                  applyKashida: demo.applyKashida,
                  removeExistingKashida: demo.removeExistingKashida,
                  fill: demo.fillStyle,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
