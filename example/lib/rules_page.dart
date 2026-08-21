import 'package:flutter/material.dart';
import 'package:kashida/kashida.dart';
import 'package:kashida_example/demo_state.dart';
import 'package:kashida_example/justify.dart' hide layoutParagraph;
import 'package:kashida_example/widgets.dart';

const _starter = '''
use arabic-naskh
@Lam ! *
''';

class RulesPage extends StatefulWidget {
  const RulesPage({super.key, required this.controller});

  final DemoController controller;

  @override
  State<RulesPage> createState() => _RulesPageState();
}

class _RulesPageState extends State<RulesPage> {
  late final TextEditingController _source = TextEditingController(
    text: _starter,
  );
  final _probe = TextEditingController(text: 'arabic-naskh');

  DemoController get demo => widget.controller;

  @override
  void dispose() {
    _source.dispose();
    _probe.dispose();
    super.dispose();
  }

  ({PatternSet? set, CompileError? error}) _compile() {
    try {
      return (set: compilePatternText(_source.text), error: null);
    } on CompileError catch (error) {
      return (set: null, error: error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final compiled = _compile();
    final probeName = _probe.text.trim();
    final known = isBuiltinPatternSet(probeName);
    final probed = builtinPatternSet(probeName);
    final set = compiled.set ?? demo.builtinSet;
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

        return ListView(
          padding: const EdgeInsets.all(listPadding),
          children: [
            Text(
              'Compile your own rules',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'A `use` line pulls in a built-in set; lines after it override. '
              'compilePatternText reports CompileError with a line number.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            DemoSection(
              title: 'Built-in lookup',
              subtitle:
                  'isBuiltinPatternSet / builtinPatternSet / requiredBuiltinPatternSet',
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _probe,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text(known ? 'built-in' : 'unknown'),
                          avatar: Icon(
                            known ? Icons.check : Icons.close,
                            size: 18,
                          ),
                        ),
                        Chip(
                          label: Text(
                            probed == null
                                ? 'builtinPatternSet → null'
                                : 'id ${probed.id} · ${probed.patterns.length} patterns',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final name in builtinPatternSetNames())
                  ActionChip(
                    label: Text('use $name'),
                    onPressed: () {
                      _source.text = 'use $name\n';
                      _probe.text = name;
                      setState(() {});
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _source,
              minLines: 6,
              maxLines: 14,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Pattern text',
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
                errorText: compiled.error == null
                    ? null
                    : 'line ${compiled.error!.lineNumber}: ${compiled.error!.kind}',
              ),
            ),
            const SizedBox(height: 16),
            if (compiled.set != null)
              DemoSection(
                title:
                    'Compiled (${compiled.set!.patterns.length} patterns, id ${compiled.set!.id ?? 'none'})',
                subtitle:
                    'fillStyleFor(custom) → ${fillStyleFor(compiled.set!).name}. '
                    'Custom sets have no builtin id, so fill defaults to Arabic unless you override.',
                child: ParagraphFrame(
                  width: paragraphWidth,
                  child: KashidaText(
                    demo.text,
                    patternSet: compiled.set!,
                    width: paragraphWidth,
                    style: demo.textStyle,
                    textScaler: scaler,
                    minKashidas: demo.minKashidas.round(),
                    maxKashidas: demo.maxKashidas.round(),
                    justified: demo.justify,
                    applyKashida: demo.applyKashida,
                    removeExistingKashida: demo.removeExistingKashida,
                    fill: demo.fillOverride ?? fillStyleFor(compiled.set!),
                  ),
                ),
              )
            else
              DemoSection(
                title: 'Falling back to ${demo.patternName}',
                subtitle: 'Fix the pattern text to preview the custom set.',
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
