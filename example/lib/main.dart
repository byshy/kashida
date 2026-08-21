import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kashida/kashida.dart';
import 'package:kashida_example/justify.dart';

void main() {
  runApp(const KashidaExampleApp());
}

class KashidaExampleApp extends StatelessWidget {
  const KashidaExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kashida example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B5E4B)),
        useMaterial3: true,
      ),
      home: const KashidaDemoPage(),
    );
  }
}

class KashidaDemoPage extends StatefulWidget {
  const KashidaDemoPage({super.key});

  @override
  State<KashidaDemoPage> createState() => _KashidaDemoPageState();
}

class _KashidaDemoPageState extends State<KashidaDemoPage> {
  final _controller = TextEditingController(text: sampleText);
  String _patternName = 'arabic-naskh';
  double _fontSize = 24;
  double _paragraphWidth = 600;
  double _minKashidas = 2;
  double _maxKashidas = 4;
  bool _justify = true;
  bool _applyKashida = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  TextStyle get _textStyle => GoogleFonts.notoNaskhArabic(
    fontSize: _fontSize,
    height: 1.5,
  );

  @override
  Widget build(BuildContext context) {
    final set = builtinPatternSet(_patternName)!;
    final text = _controller.text;
    final (_, points) = findKashidaPoints(text, set, true);

    return Scaffold(
      appBar: AppBar(title: const Text('Kashida example')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          const listPadding = 16.0;
          const boxPadding = 12.0;
          final availableWidth =
              constraints.maxWidth - listPadding * 2 - boxPadding * 2;
          final paragraphWidth = clampParagraphWidth(
            _paragraphWidth,
            availableWidth,
          );
          final lines = layoutParagraph(
            text,
            set,
            _textStyle,
            width: paragraphWidth,
            textScaler: MediaQuery.textScalerOf(context),
            minKashidas: _minKashidas.round(),
            maxKashidas: _maxKashidas.round(),
            justified: _justify,
            applyKashida: _applyKashida,
            syriac: _patternName.startsWith('syriac'),
          );
          final widthCapped = paragraphWidth < _paragraphWidth;

          return ListView(
            padding: const EdgeInsets.all(listPadding),
            children: [
              TextField(
                controller: _controller,
                minLines: 3,
                maxLines: 8,
                textDirection: TextDirection.rtl,
                style: _textStyle,
                onChanged: (_) => setState(() {}),
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
                    initialSelection: _patternName,
                    label: const Text('Pattern set'),
                    dropdownMenuEntries: [
                      for (final name in builtinPatternSetNames())
                        DropdownMenuEntry(value: name, label: name),
                    ],
                    onSelected: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() => _patternName = value);
                    },
                  ),
                  FilterChip(
                    label: const Text('Justify'),
                    selected: _justify,
                    onSelected: (value) => setState(() => _justify = value),
                  ),
                  FilterChip(
                    label: const Text('Apply kashida'),
                    selected: _applyKashida,
                    onSelected: _justify
                        ? (value) => setState(() => _applyKashida = value)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Size: ${_fontSize.round()}px'),
              Slider(
                min: 16,
                max: 48,
                divisions: 32,
                value: _fontSize,
                onChanged: (value) => setState(() => _fontSize = value),
              ),
              Text(
                widthCapped
                    ? 'Paragraph width: ${paragraphWidth.round()}px '
                        '(capped from ${_paragraphWidth.round()}px)'
                    : 'Paragraph width: ${_paragraphWidth.round()}px',
              ),
              Slider(
                min: 280,
                max: 800,
                divisions: 52,
                value: _paragraphWidth,
                onChanged: (value) => setState(() => _paragraphWidth = value),
              ),
              Text('Min kashidas per point: ${_minKashidas.round()}'),
              Slider(
                min: 1,
                max: 6,
                divisions: 5,
                value: _minKashidas,
                onChanged: (value) => setState(() => _minKashidas = value),
              ),
              Text('Max kashidas per point: ${_maxKashidas.round()}'),
              Slider(
                min: 1,
                max: 8,
                divisions: 7,
                value: _maxKashidas,
                onChanged: (value) {
                  setState(() {
                    _maxKashidas = value;
                    if (_minKashidas > _maxKashidas) {
                      _minKashidas = _maxKashidas;
                    }
                  });
                },
              ),
              const SizedBox(height: 8),
              _Section(
                title: _justify
                    ? 'Justified (last line left short)'
                    : 'Unjustified',
                child: _ParagraphView(
                  lines: lines,
                  width: paragraphWidth,
                  style: _textStyle,
                ),
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'Kashida points (${points.length})',
                child: points.isEmpty
                    ? const Text('No insertion points in this text.')
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final point in points)
                            Chip(
                              label: Text(
                                'after ${point.index} · priority ${point.priority}',
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _ParagraphView extends StatelessWidget {
  const _ParagraphView({
    required this.lines,
    required this.width,
    required this.style,
  });

  final List<JustifiedLine> lines;
  final double width;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final line in lines)
                  _JustifiedLineView(line: line, style: style),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JustifiedLineView extends StatelessWidget {
  const _JustifiedLineView({required this.line, required this.style});

  final JustifiedLine line;
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
            elongated(word),
            textDirection: TextDirection.rtl,
            softWrap: false,
            maxLines: 1,
            style: style,
          ),
      ],
    );
  }
}
