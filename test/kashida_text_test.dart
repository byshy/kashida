import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kashida/kashida.dart';

void main() {
  testWidgets('KashidaText paints the source words', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KashidaText(
            'بيت بيت',
            patternSet: requiredBuiltinPatternSet('arabic-simple'),
            width: 400,
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
    expect(find.byType(KashidaText), findsOneWidget);
    expect(find.byType(Text), findsWidgets);
  });
}
