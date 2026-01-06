import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_lob/main.dart';

void main() {
  testWidgets('Task Lob app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(
      const ProviderScope(
        child: TaskLobApp(),
      ),
    );

    // Verify we have the Catch screen visible
    expect(find.text('Catch Your Chaos'), findsOneWidget);

    // Verify bottom navigation exists
    expect(find.text('Catch'), findsOneWidget);
    expect(find.text('My Court'), findsOneWidget);
    expect(find.text('Waiting'), findsOneWidget);
  });
}
