import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../widgets/parsed_lob_card.dart';

/// The Lob Catcher - Voice/text input for catching chaos
/// This is the primary interaction point for Task Lob
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

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _initVoice();
  }

  Future<void> _initVoice() async {
    final voiceService = ref.read(voiceServiceProvider);
    await voiceService.initialize();

    voiceService.onTranscriptUpdate = (transcript) {
      ref.read(transcriptProvider.notifier).state = transcript;
    };

    voiceService.onListeningChanged = (isListening) {
      ref.read(isRecordingProvider.notifier).state = isListening;
      if (isListening) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    };

    voiceService.onError = (error) {
      ref.read(errorMessageProvider.notifier).state = error;
    };
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    HapticFeedback.mediumImpact();
    final voiceService = ref.read(voiceServiceProvider);
    await voiceService.startListening();
  }

  Future<void> _stopRecording() async {
    HapticFeedback.lightImpact();
    final voiceService = ref.read(voiceServiceProvider);
    final transcript = await voiceService.stopListening();

    if (transcript.isNotEmpty) {
      await _parseLob(transcript);
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
    final isRecording = ref.watch(isRecordingProvider);
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

          // Error display
          if (error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red.shade100,
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text(error)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      ref.read(errorMessageProvider.notifier).state = null;
                    },
                  ),
                ],
              ),
            ),

          Expanded(
            child: parsedLob != null
                ? _buildParsedResults(parsedLob)
                : _buildCaptureInterface(
                    isRecording, transcript, isParsing),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureInterface(
      bool isRecording, String transcript, bool isParsing) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Instructions
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _showTextInput
                ? 'Type your chaos below'
                : isRecording
                    ? 'Listening...'
                    : 'Hold the button to speak',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey,
                ),
            textAlign: TextAlign.center,
          ),
        ),

        // Transcript preview
        if (transcript.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              transcript,
              style: Theme.of(context).textTheme.bodyLarge,
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
              onLongPressStart: (_) => _startRecording(),
              onLongPressEnd: (_) => _stopRecording(),
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
                    child: Icon(
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

  Widget _buildParsedResults(parsedLob) {
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
              Text(
                '${parsedLob.realTasks.length} tasks, ${parsedLob.selfServiceTasks.length} self-service, ${parsedLob.reminders.length} reminders',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
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
                  parsedLob.parsedTasks[index].isSelected = selected;
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
}
