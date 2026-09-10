import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weathergpt_mobile/router/app_router.dart';

void main() {
  testWidgets('home placeholder renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PlaceholderTab(title: 'Home')),
    );

    expect(find.text('Home'), findsOneWidget);
  });
}
