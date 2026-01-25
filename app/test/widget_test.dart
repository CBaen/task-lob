import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_lob/main.dart';
import 'package:task_lob/providers/app_providers.dart';
import 'package:task_lob/services/api_service.dart';

/// Mock API service that doesn't make real HTTP calls
class MockApiService extends ApiService {
  MockApiService() : super(baseUrl: 'http://mock');

  @override
  Future<bool> healthCheck() async {
    // Return false without making HTTP call
    return false;
  }
}

void main() {
  testWidgets('Task Lob app smoke test', (WidgetTester tester) async {
    // Build our app with mocked providers to avoid HTTP calls
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Override API service to avoid real HTTP calls
          apiServiceProvider.overrideWithValue(MockApiService()),
          // Override the async health check
          apiConnectedProvider.overrideWith((ref) async => false),
        ],
        child: const TaskLobApp(),
      ),
    );

    // Allow async operations to complete
    await tester.pumpAndSettle();

    // Verify we have the Catch screen visible
    expect(find.text('Catch Your Chaos'), findsOneWidget);

    // Verify bottom navigation exists
    expect(find.text('Catch'), findsOneWidget);
    expect(find.text('My Court'), findsOneWidget);
    expect(find.text('Waiting'), findsOneWidget);
  });
}
