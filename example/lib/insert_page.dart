import 'package:flutter/material.dart';
import 'package:kashida/kashida.dart';
import 'package:kashida_example/demo_state.dart';
import 'package:kashida_example/justify.dart' hide layoutParagraph;
import 'package:kashida_example/widgets.dart';

bool _samePoints(List<KashidaPoint> a, List<KashidaPoint> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

class InsertPage extends StatefulWidget {
  const InsertPage({super.key, required this.controller});

  final DemoController controller;

  @override
  State<InsertPage> createState() => _InsertPageState();
}

class _InsertPageState extends State<InsertPage> {
  late final TextEditingController _word = TextEditingController(
    text: tatweelSample,
  );
  int _stampCount = 1;
  int _minPriority = 0;
  int? _selectedIndex;

  DemoController get demo => widget.controller;

  @override
  void dispose() {
    _word.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final set = demo.builtinSet;
    final source = _word.text;
    final stripped = stripBareTatweel(source);
    final analyzed = findKashidaPoints(
      source,
      set,
      removeExistingKashida: demo.removeExistingKashida,
    );
    final kept = findKashidaPointsIn(source, set);
    final alias = findKashidaPointsPatterns(source, set);
    final stamped = insertKashida(
      source,
      set,
      removeExistingKashida: demo.removeExistingKashida,
      count: _stampCount,
      minPriority: _minPriority,
    );
    final fromAnalysis = analyzed.insert(
      count: _stampCount,
      minPriority: _minPriority,
    );
    final selected = analyzed.points
        .where((point) => point.index == _selectedIndex)
        .toList();
    final selectedInsert = selected.isEmpty
        ? analyzed.text
        : insertKashidaAt(
            analyzed.text,
            selected,
            count: _stampCount,
            minPriority: _minPriority,
          );

    final scaler = MediaQuery.textScalerOf(context);
    double measure(String value) =>
        measureTextWidth(value, demo.textStyle, textScaler: scaler);

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
        final lines = layoutParagraph(
          analyzed.text,
          set,
          width: paragraphWidth,
          measure: measure,
          minKashidas: demo.minKashidas.round(),
          maxKashidas: demo.maxKashidas.round(),
          justified: true,
          justifyLastLine: demo.justifyLastLine,
          applyKashida: true,
          removeExistingKashida: false,
          fill: demo.fillStyle,
        );

        return ListView(
          padding: const EdgeInsets.all(listPadding),
          children: [
            Text(
              'Same points, three operations',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Find where tatweel $kashida (U+${kashidaCodepoint.toRadixString(16).toUpperCase()}) may go, '
              'stamp it at every point, or fill a width. '
              'findKashidaPointsIn == findKashidaPointsPatterns: ${_samePoints(kept, alias)}.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _word,
              textDirection: TextDirection.rtl,
              style: demo.textStyle,
              onChanged: (_) => setState(() => _selectedIndex = null),
              decoration: InputDecoration(
                labelText: 'Word or phrase',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: 'Load tatweel sample',
                  onPressed: () {
                    _word.text = tatweelSample;
                    setState(() => _selectedIndex = null);
                  },
                  icon: const Icon(Icons.restart_alt),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('Strip existing tatweel'),
                  selected: demo.removeExistingKashida,
                  onSelected: (value) {
                    demo.setRemoveExistingKashida(value);
                    setState(() {});
                  },
                ),
                ActionChip(
                  label: const Text('Use paragraph text'),
                  onPressed: () {
                    _word.text = demo.text;
                    setState(() => _selectedIndex = null);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            DemoSection(
              title: '1. Find',
              subtitle:
                  'stripBareTatweel → ${stripped == source ? 'unchanged' : stripped} · '
                  'findKashidaPoints.text → ${analyzed.text}',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _GraphemeRuler(
                    text: analyzed.text,
                    points: analyzed.points,
                    style: demo.textStyle,
                    selectedIndex: _selectedIndex,
                    onSelect: (index) => setState(() => _selectedIndex = index),
                  ),
                  const SizedBox(height: 8),
                  if (analyzed.points.isEmpty)
                    const Text('No insertion points.')
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final point in analyzed.points)
                          ChoiceChip(
                            selected: _selectedIndex == point.index,
                            onSelected: (_) =>
                                setState(() => _selectedIndex = point.index),
                            label: Text(
                              'after ${point.index} · p${point.priority} · '
                              'utf16 ${point.endOffsetIn(analyzed.text)}',
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Without stripping (${kept.length} points) vs '
                    'with stripping (${analyzed.points.length} points).',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            DemoSection(
              title: '2. Stamp every allowed join',
              subtitle:
                  'insertKashida and KashidaAnalysis.insert — not justification',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Count: $_stampCount  ·  min priority: $_minPriority'),
                  Slider(
                    min: 1,
                    max: 4,
                    divisions: 3,
                    value: _stampCount.toDouble(),
                    label: '$_stampCount',
                    onChanged: (value) =>
                        setState(() => _stampCount = value.round()),
                  ),
                  Slider(
                    min: 0,
                    max: 9,
                    divisions: 9,
                    value: _minPriority.toDouble(),
                    label: '$_minPriority',
                    onChanged: (value) =>
                        setState(() => _minPriority = value.round()),
                  ),
                  ParagraphFrame(
                    width: paragraphWidth,
                    child: Text(
                      stamped,
                      textDirection: TextDirection.rtl,
                      style: demo.textStyle,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'analysis.insert matches insertKashida: ${fromAnalysis == stamped}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (_selectedIndex != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'insertKashidaAt on the selected point:',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    ParagraphFrame(
                      width: paragraphWidth,
                      child: Text(
                        selectedInsert,
                        textDirection: TextDirection.rtl,
                        style: demo.textStyle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            DemoSection(
              title: '3. Fill a width',
              subtitle:
                  'layoutParagraph with a measure callback — leftover thinner than one tatweel stays as unusedWidth',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ParagraphFrame(
                    width: paragraphWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final line in lines)
                          _LaidOutLine(line: line, style: demo.textStyle),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < lines.length; i++)
                    Text(
                      'Line ${i + 1}: ${lines[i].words.length} words · '
                      '${lines[i].stretch ? 'stretch' : 'last'} · '
                      'unused ${lines[i].unusedWidth(paragraphWidth, measure).toStringAsFixed(1)}px',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LaidOutLine extends StatelessWidget {
  const _LaidOutLine({required this.line, required this.style});

  final KashidaLine line;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    if (!line.stretch || line.words.length < 2) {
      return Text(
        line.text,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.start,
        softWrap: false,
        maxLines: 1,
        style: style,
      );
    }
    return Row(
      textDirection: TextDirection.rtl,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final word in line.words)
          Text(
            word.elongated(),
            textDirection: TextDirection.rtl,
            softWrap: false,
            maxLines: 1,
            style: style,
          ),
      ],
    );
  }
}

class _GraphemeRuler extends StatelessWidget {
  const _GraphemeRuler({
    required this.text,
    required this.points,
    required this.style,
    required this.selectedIndex,
    required this.onSelect,
  });

  final String text;
  final List<KashidaPoint> points;
  final TextStyle style;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final clusters = text.characters.toList();
    final after = {for (final point in points) point.index: point};
    return Wrap(
      textDirection: TextDirection.rtl,
      spacing: 2,
      runSpacing: 4,
      children: [
        for (var i = 0; i < clusters.length; i++)
          Tooltip(
            message: after[i] == null
                ? 'grapheme $i'
                : 'kashida after $i, priority ${after[i]!.priority}',
            child: InkWell(
              onTap: () => onSelect(i),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    left: after[i] == null
                        ? BorderSide.none
                        : BorderSide(
                            color: selectedIndex == i
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.tertiary,
                            width: 3,
                          ),
                  ),
                  color: selectedIndex == i
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Text(clusters[i], style: style),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
