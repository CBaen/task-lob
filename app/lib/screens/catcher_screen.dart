import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import '../providers/app_providers.dart';
import '../services/voice_service.dart';
import '../widgets/parsed_lob_card.dart';
import '../widgets/entity_disambiguation_card.dart';
import '../models/parsed_lob.dart';

/// The Lob Catcher - Voice/text input for catching chaos
/// This is the primary interaction point for Task Lob
///
/// Flow: Hold button → Record audio → Release → Upload to API →
///       Groq Whisper transcribes → Mistral parses → Display results
class CatcherScreen extends ConsumerStatefulWidget {
  const CatcherScreen({super.key});

  @override
  ConsumerState<CatcherScreen> createState() => _CatcherScreenState();
}

class _CatcherScreenState extends ConsumerState<CatcherScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final TextEditingController _textController = TextEditingController();
  bool _showTextInput = false;

  bool _voiceInitialized = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  void _setupVoiceCallbacks() {
    if (_voiceInitialized) return;
    _voiceInitialized = true;

    final voiceService = ref.read(voiceServiceProvider);

    voiceService.onStateChanged = (state) {
      if (mounted) {
        // Use Future.microtask to avoid modifying state during build
        Future.microtask(() {
          if (mounted) {
            ref.read(voiceStateProvider.notifier).state = state;

            if (state == VoiceState.listening) {
              _pulseController.repeat(reverse: true);
            } else {
              _pulseController.stop();
              _pulseController.reset();
            }
          }
        });
      }
    };

    voiceService.onError = (error) {
      if (mounted) {
        Future.microtask(() {
          if (mounted) {
            ref.read(voiceErrorProvider.notifier).state = error;
          }
        });
      }
    };
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    // Setup callbacks on first use
    _setupVoiceCallbacks();

    // Clear previous errors and transcript
    ref.read(voiceErrorProvider.notifier).state = null;
    ref.read(transcriptProvider.notifier).state = '';

    HapticFeedback.mediumImpact();
    final voiceService = ref.read(voiceServiceProvider);
    await voiceService.startListening();
  }

  Future<void> _stopRecording() async {
    HapticFeedback.lightImpact();

    final voiceService = ref.read(voiceServiceProvider);
    final audioFile = await voiceService.stopListening();

    if (audioFile == null) {
      // Error already set by VoiceService
      return;
    }

    // Upload to API for transcription and parsing
    await _transcribeAndParse(audioFile);
  }

  Future<void> _transcribeAndParse(file) async {
    ref.read(isParsingProvider.notifier).state = true;
    ref.read(errorMessageProvider.notifier).state = null;

    try {
      final api = ref.read(apiServiceProvider);

      // Use the combined transcribe+parse endpoint
      final result = await api.transcribeAndParse(audioFile: file);

      // Show the transcript
      ref.read(transcriptProvider.notifier).state = result.transcript.text;

      // Show the parsed tasks
      ref.read(parsedLobProvider.notifier).state = result.parsed;
    } catch (e) {
      ref.read(errorMessageProvider.notifier).state =
          'Failed to transcribe: ${e.toString()}';
    } finally {
      ref.read(isParsingProvider.notifier).state = false;
    }
  }

  Future<void> _parseLob(String input) async {
    if (input.trim().isEmpty) return;

    ref.read(isParsingProvider.notifier).state = true;
    ref.read(errorMessageProvider.notifier).state = null;

    try {
      final api = ref.read(apiServiceProvider);
      final userId = ref.read(currentUserIdProvider);

      final parsed = await api.parseLob(
        input: input,
        sender: userId,
      );

      ref.read(parsedLobProvider.notifier).state = parsed;
      ref.read(transcriptProvider.notifier).state = '';
      _textController.clear();
    } catch (e) {
      ref.read(errorMessageProvider.notifier).state =
          'Failed to parse: ${e.toString()}';
    } finally {
      ref.read(isParsingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceStateProvider);
    final voiceError = ref.watch(voiceErrorProvider);
    final transcript = ref.watch(transcriptProvider);
    final isParsing = ref.watch(isParsingProvider);
    final parsedLob = ref.watch(parsedLobProvider);
    final error = ref.watch(errorMessageProvider);
    final apiStatus = ref.watch(apiConnectedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catch Your Chaos'),
        centerTitle: true,
        actions: [
          // Toggle text input
          IconButton(
            icon: Icon(_showTextInput ? Icons.mic : Icons.keyboard),
            onPressed: () {
              setState(() {
                _showTextInput = !_showTextInput;
              });
            },
            tooltip: _showTextInput ? 'Switch to voice' : 'Switch to text',
          ),
        ],
      ),
      body: Column(
        children: [
          // API Status indicator
          apiStatus.when(
            data: (connected) => connected
                ? const SizedBox.shrink()
                : Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    color: Colors.orange,
                    child: const Text(
                      'API not connected - check server',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.red,
              child: const Text(
                'API connection error',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),

          // Voice error display
          if (voiceError != null)
            _buildErrorBanner(
              voiceError,
              isPermissionError: voiceError.contains('permission'),
              onDismiss: () {
                ref.read(voiceErrorProvider.notifier).state = null;
              },
            ),

          // General error display
          if (error != null)
            _buildErrorBanner(
              error,
              onDismiss: () {
                ref.read(errorMessageProvider.notifier).state = null;
              },
            ),

          Expanded(
            child: parsedLob != null
                ? _buildParsedResults(parsedLob)
                : _buildCaptureInterface(
                    voiceState, transcript, isParsing),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(
    String message, {
    bool isPermissionError = false,
    VoidCallback? onDismiss,
  }) {
    final voiceService = ref.read(voiceServiceProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.red.shade100,
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
          if (isPermissionError)
            TextButton(
              onPressed: () => voiceService.openSettings(),
              child: const Text('Settings'),
            ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureInterface(
      VoiceState voiceState, String transcript, bool isParsing) {
    final isRecording = voiceState == VoiceState.listening;
    final isProcessing = voiceState == VoiceState.processing || isParsing;
    final isInitializing = voiceState == VoiceState.initializing;
    final voiceService = ref.read(voiceServiceProvider);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Instructions
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _showTextInput
                ? 'Type your chaos below'
                : isInitializing
                    ? 'Initializing...'
                    : isProcessing
                        ? 'Transcribing with Groq Whisper...'
                        : isRecording
                            ? 'Recording...'
                            : 'Hold the button to speak',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey,
                ),
            textAlign: TextAlign.center,
          ),
        ),

        // Waveform visualization during recording
        if (isRecording && !_showTextInput && voiceService.recorderController != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            height: 60,
            child: AudioWaveforms(
              recorderController: voiceService.recorderController!,
              size: Size(MediaQuery.of(context).size.width - 48, 60),
              waveStyle: WaveStyle(
                waveColor: Theme.of(context).colorScheme.primary,
                extendWaveform: true,
                showMiddleLine: false,
                spacing: 8.0,
                waveThickness: 4.0,
              ),
            ),
          ),

        // Transcript preview (shown after transcription completes)
        if (transcript.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Transcribed via Groq Whisper',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  transcript,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),

        const Spacer(),

        // Text input mode
        if (_showTextInput)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _textController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText:
                        'Type or paste your chaos here...\n\nExample: "Hey can you check why the invoice is wrong and also remind me to call Sarah tomorrow and I hate how the new system keeps logging me out"',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: isParsing
                      ? null
                      : () => _parseLob(_textController.text),
                  icon: isParsing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(isParsing ? 'Parsing...' : 'Catch This Lob'),
                ),
              ],
            ),
          )
        else
          // Push-to-talk button
          Padding(
            padding: const EdgeInsets.only(bottom: 48),
            child: GestureDetector(
              onLongPressStart: isProcessing || isInitializing
                  ? null
                  : (_) => _startRecording(),
              onLongPressEnd: isRecording
                  ? (_) => _stopRecording()
                  : null,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 120 + (_pulseController.value * 20),
                    height: 120 + (_pulseController.value * 20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isRecording
                          ? Theme.of(context).colorScheme.primary
                          : isProcessing || isInitializing
                              ? Theme.of(context).colorScheme.surfaceContainerHigh
                              : Theme.of(context).colorScheme.primaryContainer,
                      boxShadow: isRecording
                          ? [
                              BoxShadow(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ]
                          : null,
                    ),
                    child: isProcessing || isInitializing
                        ? const Center(child: CircularProgressIndicator())
                        : Icon(
                            Icons.mic,
                            size: 48,
                            color: isRecording
                                ? Colors.white
                                : Theme.of(context).colorScheme.primary,
                          ),
                  );
                },
              ),
            ),
          ),

        const Spacer(),
      ],
    );
  }

  Widget _buildParsedResults(ParsedLob parsedLob) {
    return Column(
      children: [
        // Summary header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Column(
            children: [
              Text(
                'Caught ${parsedLob.taskCount} item${parsedLob.taskCount == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${parsedLob.realTasks.length} tasks, ${parsedLob.selfServiceTasks.length} self-service, ${parsedLob.reminders.length} reminders',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (parsedLob.entities.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${parsedLob.entities.length} entities',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // Disambiguation banner if needed
        if (parsedLob.hasAmbiguousEntities)
          AmbiguousEntitiesBanner(
            entities: parsedLob.ambiguousEntities,
            onResolve: () => _showDisambiguationSheet(parsedLob),
          ),

        // Parsed items list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: parsedLob.parsedTasks.length,
            itemBuilder: (context, index) {
              return ParsedLobCard(
                task: parsedLob.parsedTasks[index],
                onToggle: (selected) {
                  setState(() {
                    parsedLob.parsedTasks[index].isSelected = selected;
                  });
                },
              );
            },
          ),
        ),

        // Action buttons
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(parsedLobProvider.notifier).state = null;
                      ref.read(transcriptProvider.notifier).state = '';
                    },
                    child: const Text('Start Over'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () {
                      // TODO: Send selected tasks
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tasks would be sent here!'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.send),
                    label: const Text('Send Tasks'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showDisambiguationSheet(ParsedLob parsedLob) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.help_outline),
                  const SizedBox(width: 8),
                  Text(
                    'Clarify ${parsedLob.ambiguousCount} ${parsedLob.ambiguousCount == 1 ? 'Entity' : 'Entities'}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Disambiguation cards
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: parsedLob.ambiguousEntities.length,
                itemBuilder: (context, index) {
                  final entity = parsedLob.ambiguousEntities[index];
                  return EntityDisambiguationCard(
                    entity: entity,
                    onSelect: (match) {
                      setState(() {
                        entity.isResolved = true;
                        entity.resolvedTo = match.id;
                        entity.resolvedName = match.name;
                      });
                      // If all resolved, close sheet
                      if (!parsedLob.ambiguousEntities.any((e) => !e.isResolved)) {
                        Navigator.pop(context);
                      }
                    },
                    onAddNew: () {
                      // TODO: Show add entity dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Would add "${entity.mention}" as new ${entity.type}'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Done button
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
