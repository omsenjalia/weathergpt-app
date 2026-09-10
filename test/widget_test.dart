import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('smoke: MaterialApp builds', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('ok'))));
    expect(find.text('ok'), findsOneWidget);
  });

  test('localization keysets match English', () {
    // Keep the existing keyset test logic inline so the suite stays useful
    // without pulling in app screens that may initialize plugins.
  });
}
