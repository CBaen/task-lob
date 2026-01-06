import 'package:dio/dio.dart';
import '../models/parsed_lob.dart';

/// Service for communicating with the Task Lob API
class ApiService {
  final Dio _dio;
  final String baseUrl;

  ApiService({
    required this.baseUrl,
  }) : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
          },
        ));

  /// Check if the API is healthy
  Future<bool> healthCheck() async {
    try {
      final response = await _dio.get('/api/health');
      return response.data['status'] == 'ok';
    } catch (e) {
      return false;
    }
  }

  /// Parse a lob (voice/text input) into discrete tasks
  ///
  /// This is the core lob-catching functionality.
  /// Returns a ParsedLob with all detected tasks, self-service items,
  /// reminders, and venting.
  Future<ParsedLob> parseLob({
    required String input,
    required String sender,
    Map<String, dynamic>? companyContext,
  }) async {
    final response = await _dio.post('/api/lob/parse', data: {
      'input': input,
      'sender': sender,
      'companyContext': companyContext,
    });

    return ParsedLob.fromJson(response.data);
  }

  /// Run the test endpoint to verify lob parsing is working
  Future<Map<String, dynamic>> testParsing() async {
    final response = await _dio.get('/api/lob/test');
    return response.data;
  }
}

/// Singleton instance for the app
/// Configure with actual URL in production
ApiService createApiService() {
  // Default to localhost for development
  // This will be configured via environment/settings in production
  // Port 3001 to avoid conflicts with other dev servers
  const baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3001',
  );

  return ApiService(baseUrl: baseUrl);
}
