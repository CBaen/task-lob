import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/voice_service.dart';
import '../models/parsed_lob.dart';
import '../models/task.dart';

/// API Service provider
final apiServiceProvider = Provider<ApiService>((ref) {
  // Use 10.0.2.2 for Android emulator to reach host localhost
  // Use localhost for desktop/web
  const baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:3001', // Android emulator default
  );
  return ApiService(baseUrl: baseUrl);
});

/// Voice Service provider
final voiceServiceProvider = Provider<VoiceService>((ref) {
  return VoiceService();
});

/// Current user ID (placeholder - will be auth in future)
final currentUserIdProvider = StateProvider<String>((ref) {
  return 'user_placeholder';
});

/// Voice recording state
final isRecordingProvider = StateProvider<bool>((ref) => false);

/// Current transcript while recording
final transcriptProvider = StateProvider<String>((ref) => '');

/// Parsed lob result after catching
final parsedLobProvider = StateProvider<ParsedLob?>((ref) => null);

/// Loading state for parsing
final isParsingProvider = StateProvider<bool>((ref) => false);

/// Tasks in MY court (I need to act)
final myCourtTasksProvider = StateProvider<List<Task>>((ref) => []);

/// Tasks waiting on OTHERS
final waitingTasksProvider = StateProvider<List<Task>>((ref) => []);

/// All tasks
final allTasksProvider = StateProvider<List<Task>>((ref) => []);

/// Error message state
final errorMessageProvider = StateProvider<String?>((ref) => null);

/// API connection status
final apiConnectedProvider = FutureProvider<bool>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.healthCheck();
});
