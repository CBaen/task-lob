import 'dart:io';
import 'package:dio/dio.dart';
import '../models/parsed_lob.dart';

/// Result from transcribing audio
class TranscriptionResult {
  final String text;
  final double? duration;
  final String? language;
  final String provider;
  final String model;

  TranscriptionResult({
    required this.text,
    this.duration,
    this.language,
    required this.provider,
    required this.model,
  });

  factory TranscriptionResult.fromJson(Map<String, dynamic> json) {
    return TranscriptionResult(
      text: json['text'] ?? '',
      duration: (json['duration'] as num?)?.toDouble(),
      language: json['language'],
      provider: json['provider'] ?? 'unknown',
      model: json['model'] ?? 'unknown',
    );
  }
}

/// Result from transcribing and parsing in one call
class TranscribeAndParseResult {
  final TranscriptionResult transcript;
  final ParsedLob parsed;

  TranscribeAndParseResult({
    required this.transcript,
    required this.parsed,
  });
}

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

  /// Transcribe audio using Groq Whisper
  ///
  /// Uploads the audio file to the API for server-side transcription.
  /// This is the "lob" - user speaks, releases, gets clean transcript.
  Future<TranscriptionResult> transcribeAudio({
    required File audioFile,
    String? language,
  }) async {
    final formData = FormData.fromMap({
      'audio': await MultipartFile.fromFile(
        audioFile.path,
        filename: audioFile.path.split('/').last,
      ),
    });

    final queryParams = <String, dynamic>{};
    if (language != null) queryParams['language'] = language;

    final response = await _dio.post(
      '/api/lob/transcribe',
      data: formData,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );

    return TranscriptionResult.fromJson(response.data);
  }

  /// Transcribe and parse in one call
  ///
  /// Uploads audio, transcribes via Groq Whisper, then parses the
  /// transcript into tasks. The complete "lob" flow in one request.
  Future<TranscribeAndParseResult> transcribeAndParse({
    required File audioFile,
    String? language,
  }) async {
    final formData = FormData.fromMap({
      'audio': await MultipartFile.fromFile(
        audioFile.path,
        filename: audioFile.path.split('/').last,
      ),
    });

    final response = await _dio.post(
      '/api/lob/transcribe',
      data: formData,
      queryParameters: {'parse': 'true', if (language != null) 'language': language},
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );

    final data = response.data;
    return TranscribeAndParseResult(
      transcript: TranscriptionResult.fromJson(data['transcript']),
      parsed: ParsedLob.fromJson(data),
    );
  }

  /// Get transcription provider info
  Future<Map<String, dynamic>> getTranscriptionInfo() async {
    final response = await _dio.get('/api/lob/transcription-info');
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
