/// Represents the result of parsing a "lob" (chaotic input)
/// This is what the AI Proxy returns after catching a lob
class ParsedLob {
  final String lobId;
  final String rawInput;
  final String sender;
  final List<ParsedTask> parsedTasks;
  final DateTime timestamp;

  ParsedLob({
    required this.lobId,
    required this.rawInput,
    required this.sender,
    required this.parsedTasks,
    required this.timestamp,
  });

  factory ParsedLob.fromJson(Map<String, dynamic> json) {
    return ParsedLob(
      lobId: json['lobId'],
      rawInput: json['rawInput'],
      sender: json['sender'],
      parsedTasks: (json['parsedTasks'] as List)
          .map((t) => ParsedTask.fromJson(t))
          .toList(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  /// Number of tasks parsed from this lob
  int get taskCount => parsedTasks.length;

  /// Tasks that are actual work items (not self-service/reminders/venting)
  List<ParsedTask> get realTasks =>
      parsedTasks.where((t) => t.classification == 'task').toList();

  /// Tasks the sender can handle themselves
  List<ParsedTask> get selfServiceTasks =>
      parsedTasks.where((t) => t.classification == 'self_service').toList();

  /// Reminder items
  List<ParsedTask> get reminders =>
      parsedTasks.where((t) => t.classification == 'reminder').toList();

  /// Venting that was acknowledged
  List<ParsedTask> get venting =>
      parsedTasks.where((t) => t.classification == 'venting').toList();
}

/// A single parsed task from a lob (before it's saved to the database)
class ParsedTask {
  final int position;
  final String rawChunk;
  final String summary;
  final String classification;
  final String? system;
  final String urgency;
  final String? deadline;
  final List<String> missingInfo;
  final List<String>? selfServiceSteps;
  final String? ventingResponse;

  /// User can edit before sending
  bool isSelected = true;
  String? editedSummary;
  String? editedRoute;

  ParsedTask({
    required this.position,
    required this.rawChunk,
    required this.summary,
    required this.classification,
    this.system,
    required this.urgency,
    this.deadline,
    this.missingInfo = const [],
    this.selfServiceSteps,
    this.ventingResponse,
  });

  factory ParsedTask.fromJson(Map<String, dynamic> json) {
    return ParsedTask(
      position: json['position'],
      rawChunk: json['rawChunk'],
      summary: json['summary'],
      classification: json['classification'],
      system: json['system'],
      urgency: json['urgency'],
      deadline: json['deadline'],
      missingInfo: List<String>.from(json['missingInfo'] ?? []),
      selfServiceSteps: json['selfServiceSteps'] != null
          ? List<String>.from(json['selfServiceSteps'])
          : null,
      ventingResponse: json['ventingResponse'],
    );
  }

  /// The summary to display (edited or original)
  String get displaySummary => editedSummary ?? summary;

  /// Is this a self-service item?
  bool get isSelfService => classification == 'self_service';

  /// Is this venting?
  bool get isVenting => classification == 'venting';

  /// Is this a reminder?
  bool get isReminder => classification == 'reminder';

  /// Does this need clarification?
  bool get needsInfo => missingInfo.isNotEmpty;

  /// Is this urgent or has a deadline?
  bool get isUrgent => urgency == 'urgent' || urgency == 'deadline';
}
