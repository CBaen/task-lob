import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

/// Service for handling voice input (push-to-talk)
class VoiceService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  /// Current transcript being built
  String _currentTranscript = '';

  /// Callback for when transcription updates
  Function(String)? onTranscriptUpdate;

  /// Callback for when listening state changes
  Function(bool)? onListeningChanged;

  /// Callback for when an error occurs
  Function(String)? onError;

  /// Initialize the speech recognition
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    _isInitialized = await _speech.initialize(
      onError: (error) {
        onError?.call(error.errorMsg);
      },
      onStatus: (status) {
        final isListening = status == 'listening';
        if (_isListening != isListening) {
          _isListening = isListening;
          onListeningChanged?.call(isListening);
        }
      },
    );

    return _isInitialized;
  }

  /// Check if speech recognition is available
  bool get isAvailable => _isInitialized;

  /// Check if currently listening
  bool get isListening => _isListening;

  /// Get the current transcript
  String get transcript => _currentTranscript;

  /// Start listening (push-to-talk start)
  Future<void> startListening() async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        onError?.call('Speech recognition not available');
        return;
      }
    }

    _currentTranscript = '';

    await _speech.listen(
      onResult: _onResult,
      listenFor: const Duration(minutes: 2), // Max 2 minutes
      pauseFor: const Duration(seconds: 3), // Pause detection
      partialResults: true,
      cancelOnError: false,
      listenMode: ListenMode.dictation,
    );

    _isListening = true;
    onListeningChanged?.call(true);
  }

  /// Stop listening (push-to-talk release)
  Future<String> stopListening() async {
    await _speech.stop();
    _isListening = false;
    onListeningChanged?.call(false);

    return _currentTranscript;
  }

  /// Cancel listening without returning result
  Future<void> cancelListening() async {
    await _speech.cancel();
    _isListening = false;
    _currentTranscript = '';
    onListeningChanged?.call(false);
  }

  /// Handle speech recognition results
  void _onResult(SpeechRecognitionResult result) {
    _currentTranscript = result.recognizedWords;
    onTranscriptUpdate?.call(_currentTranscript);
  }

  /// Get available locales
  Future<List<LocaleName>> getLocales() async {
    if (!_isInitialized) await initialize();
    return _speech.locales();
  }

  /// Dispose resources
  void dispose() {
    _speech.stop();
  }
}
