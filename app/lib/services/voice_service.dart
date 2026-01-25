import 'dart:io';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

/// Voice input states for UI feedback
enum VoiceState {
  idle,           // Not recording
  initializing,   // Setting up
  listening,      // Actively recording audio
  processing,     // Uploading to API for transcription
  error,          // Something went wrong
}

/// Service for handling voice input (push-to-talk)
///
/// Records audio to a file for server-side transcription via Groq Whisper.
/// This is the "lob" approach - record locally, transcribe remotely.
class VoiceService {
  RecorderController? _recorder;
  VoiceState _state = VoiceState.idle;
  String _errorMessage = '';
  String? _currentRecordingPath;
  bool _isInitialized = false;

  /// Callback for when voice state changes
  Function(VoiceState)? onStateChanged;

  /// Callback for when an error occurs
  Function(String)? onError;

  /// Current voice state
  VoiceState get state => _state;

  /// Current error message (if any)
  String get errorMessage => _errorMessage;

  /// Check if recording is available
  bool get isAvailable => _isInitialized;

  /// Check if currently listening
  bool get isListening => _state == VoiceState.listening;

  /// Get the recorder controller for waveform visualization
  RecorderController? get recorderController => _recorder;

  /// Update state and notify listeners
  void _setState(VoiceState newState) {
    _state = newState;
    onStateChanged?.call(newState);
  }

  /// Check and request microphone permission
  Future<bool> _checkPermission() async {
    var status = await Permission.microphone.status;

    if (status.isDenied) {
      status = await Permission.microphone.request();
    }

    if (status.isPermanentlyDenied) {
      _errorMessage = 'Microphone permission permanently denied. Please enable in Settings.';
      _setState(VoiceState.error);
      onError?.call(_errorMessage);
      return false;
    }

    if (!status.isGranted) {
      _errorMessage = 'Microphone permission required for voice input.';
      _setState(VoiceState.error);
      onError?.call(_errorMessage);
      return false;
    }

    return true;
  }

  /// Initialize the recorder
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    _setState(VoiceState.initializing);

    // Check permissions first
    final hasPermission = await _checkPermission();
    if (!hasPermission) return false;

    try {
      _recorder = RecorderController()
        ..androidEncoder = AndroidEncoder.aac
        ..androidOutputFormat = AndroidOutputFormat.mpeg4
        ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
        ..sampleRate = 44100
        ..bitRate = 128000;

      _isInitialized = true;
      _setState(VoiceState.idle);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to initialize recorder: $e';
      _setState(VoiceState.error);
      onError?.call(_errorMessage);
      return false;
    }
  }

  /// Get a temporary file path for recording
  Future<String> _getRecordingPath() async {
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${directory.path}/lob_$timestamp.m4a';
  }

  /// Start recording (push-to-talk start)
  Future<bool> startListening() async {
    // Clear previous error
    _errorMessage = '';

    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return false;
    }

    // Double-check permissions each time
    final hasPermission = await _checkPermission();
    if (!hasPermission) return false;

    try {
      _currentRecordingPath = await _getRecordingPath();

      await _recorder?.record(path: _currentRecordingPath!);
      _setState(VoiceState.listening);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to start recording: $e';
      _setState(VoiceState.error);
      onError?.call(_errorMessage);
      return false;
    }
  }

  /// Stop recording and return the audio file
  ///
  /// Returns the File containing the recording, or null if failed.
  /// The caller should upload this to the API for transcription.
  Future<File?> stopListening() async {
    _setState(VoiceState.processing);

    try {
      final path = await _recorder?.stop();

      if (path == null || path.isEmpty) {
        _errorMessage = 'No recording captured.';
        _setState(VoiceState.error);
        onError?.call(_errorMessage);
        return null;
      }

      final file = File(path);
      if (!await file.exists()) {
        _errorMessage = 'Recording file not found.';
        _setState(VoiceState.error);
        onError?.call(_errorMessage);
        return null;
      }

      // Check file has content
      final size = await file.length();
      if (size < 1000) { // Less than 1KB probably means empty
        _errorMessage = 'Recording too short. Hold the button while speaking.';
        _setState(VoiceState.error);
        onError?.call(_errorMessage);
        return null;
      }

      _setState(VoiceState.idle);
      return file;
    } catch (e) {
      _errorMessage = 'Failed to stop recording: $e';
      _setState(VoiceState.error);
      onError?.call(_errorMessage);
      return null;
    }
  }

  /// Cancel recording without returning result
  Future<void> cancelListening() async {
    try {
      await _recorder?.stop();

      // Delete the cancelled recording
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      // Ignore cancel errors
    }
    _currentRecordingPath = null;
    _setState(VoiceState.idle);
  }

  /// Open app settings (for permission management)
  Future<void> openSettings() async {
    await openAppSettings();
  }

  /// Dispose resources
  void dispose() {
    _recorder?.dispose();
    _recorder = null;
    _isInitialized = false;
  }
}
