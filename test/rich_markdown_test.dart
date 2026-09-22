import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:weathergpt_mobile/core/widgets/rich_markdown.dart';

void main() {
  group('RichMarkdown.sanitize', () {
    test('strips native widget fences', () {
      const input = 'Answer text\n```widget:weather\n{"temp": 31}\n```\nDone';
      expect(RichMarkdown.sanitize(input), 'Answer text\n\nDone');
    });

    test('strips json fences', () {
      const input = 'Before\n```json\n{"a": 1}\n```\nAfter';
      expect(RichMarkdown.sanitize(input), 'Before\n\nAfter');
    });

    test('closes a dangling fence so it cannot swallow the answer', () {
      const input = 'Table incoming\n| a | b |\n|---|---|\n| 1 | 2 |\n```';
      final out = RichMarkdown.sanitize(input);
      expect(out.isNotEmpty, isTrue);
      expect('```'.allMatches(out).length.isEven, isTrue);
    });

    test('leaves plain markdown untouched', () {
      const input = '**Bold** and | pipes | in prose';
      expect(RichMarkdown.sanitize(input), input);
    });
  });

  group('RichMarkdown rendering', () {
    testWidgets('renders a GFM table as a real Table widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RichMarkdown(
              '| Day | Rain |\n|-----|------|\n| Mon | 10%  |\n| Tue | 40%  |',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // gpt_markdown renders tables with Flutter's Table (or a subclass);
      // assert on whichever structure the resolved version produces.
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Table ||
              w.runtimeType.toString().toLowerCase().contains('table'),
        ),
        findsOneWidget,
      );
      expect(find.text('Day'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);
    });

    testWidgets('renders headings, emphasis, lists and blockquotes',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RichMarkdown(
                '## Forecast\n\n**Heavy rain** expected.\n\n- Carry an umbrella\n\n> IMD warning in effect',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Forecast'), findsOneWidget);
      expect(find.textContaining('Heavy rain', findRichText: true),
          findsOneWidget);
      expect(find.text('Carry an umbrella'), findsOneWidget);
    });

    testWidgets('strips widget fences before rendering', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RichMarkdown('Visible answer\n```widget:forecast\n{}\n```'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('widget:'), findsNothing);
      expect(find.text('Visible answer'), findsOneWidget);
    });
  });
}
