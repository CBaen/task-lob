/// Represents an extracted entity from the lob
class ExtractedEntity {
  final String mention;
  final String type; // person, company, system, account, date
  final String role; // assignee, mentioned, deadline
  final double confidence;
  final List<String> contextClues;

  // Resolution status (filled after entity resolution)
  bool isResolved = false;
  String? resolvedTo;
  String? resolvedName;
  List<EntityMatch>? possibleMatches;
  String? clarificationQuestion;

  ExtractedEntity({
    required this.mention,
    required this.type,
    required this.role,
    required this.confidence,
    this.contextClues = const [],
  });

  factory ExtractedEntity.fromJson(Map<String, dynamic> json) {
    return ExtractedEntity(
      mention: json['mention'] ?? '',
      type: json['type'] ?? 'unknown',
      role: json['role'] ?? 'mentioned',
      confidence: (json['confidence'] ?? 0.5).toDouble(),
      contextClues: List<String>.from(json['contextClues'] ?? []),
    );
  }

  /// Is this entity ambiguous (needs user selection)?
  bool get isAmbiguous => !isResolved && (possibleMatches?.isNotEmpty ?? false);

  /// Is this entity completely unknown (needs to be added)?
  bool get isUnknown => !isResolved && (possibleMatches?.isEmpty ?? true);

  /// Display name (resolved or original mention)
  String get displayName => resolvedName ?? mention;

  /// Icon for entity type
  String get typeIcon {
    switch (type) {
      case 'person': return '👤';
      case 'company': return '🏢';
      case 'system': return '💻';
      case 'account': return '🔑';
      case 'date': return '📅';
      default: return '❓';
    }
  }
}

/// A possible match for an ambiguous entity
class EntityMatch {
  final String id;
  final String name;
  final double confidence;
  final String? role;
  final String? email;

  EntityMatch({
    required this.id,
    required this.name,
    required this.confidence,
    this.role,
    this.email,
  });

  factory EntityMatch.fromJson(Map<String, dynamic> json) {
    return EntityMatch(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      confidence: (json['confidence'] ?? 0.5).toDouble(),
      role: json['role'],
      email: json['email'],
    );
  }
}

/// Represents the result of parsing a "lob" (chaotic input)
/// This is what the AI Proxy returns after catching a lob
class ParsedLob {
  final String lobId;
  final String rawInput;
  final String sender;
  final List<ParsedTask> parsedTasks;
  final List<ExtractedEntity> entities;
  final List<ExtractedEntity> ambiguousEntities;
  final DateTime timestamp;

  ParsedLob({
    required this.lobId,
    required this.rawInput,
    required this.sender,
    required this.parsedTasks,
    this.entities = const [],
    this.ambiguousEntities = const [],
    required this.timestamp,
  });

  factory ParsedLob.fromJson(Map<String, dynamic> json) {
    // Handle both simple and enriched response formats
    List<ExtractedEntity> extractedEntities = [];
    List<ExtractedEntity> ambiguous = [];

    if (json['entities'] is Map) {
      // Enriched format with resolved/ambiguous
      final entitiesMap = json['entities'] as Map<String, dynamic>;
      extractedEntities = (entitiesMap['extracted'] as List? ?? [])
          .map((e) => ExtractedEntity.fromJson(e))
          .toList();

      // Mark resolved entities
      for (final resolved in (entitiesMap['resolved'] as List? ?? [])) {
        final entity = extractedEntities.firstWhere(
          (e) => e.mention == resolved['mention'],
          orElse: () => ExtractedEntity.fromJson(resolved),
        );
        entity.isResolved = true;
        entity.resolvedTo = resolved['resolvedTo'];
        entity.resolvedName = resolved['resolvedName'];
      }

      // Mark ambiguous entities
      ambiguous = (entitiesMap['ambiguous'] as List? ?? []).map((a) {
        final entity = ExtractedEntity.fromJson(a);
        entity.possibleMatches = (a['possibleMatches'] as List? ?? [])
            .map((m) => EntityMatch.fromJson(m))
            .toList();
        entity.clarificationQuestion = a['clarificationQuestion'];
        return entity;
      }).toList();
    } else if (json['entities'] is List) {
      // Simple format - just extracted entities
      extractedEntities = (json['entities'] as List)
          .map((e) => ExtractedEntity.fromJson(e))
          .toList();
    }

    return ParsedLob(
      lobId: json['lobId'] ?? '',
      rawInput: json['rawInput'] ?? '',
      sender: json['sender'] ?? 'unknown',
      parsedTasks: (json['parsedTasks'] as List? ?? [])
          .map((t) => ParsedTask.fromJson(t))
          .toList(),
      entities: extractedEntities,
      ambiguousEntities: ambiguous,
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }

  /// Number of tasks parsed from this lob
  int get taskCount => parsedTasks.length;

  /// Are there ambiguous entities that need user selection?
  bool get hasAmbiguousEntities => ambiguousEntities.isNotEmpty;

  /// Number of entities needing disambiguation
  int get ambiguousCount => ambiguousEntities.length;

  /// People entities extracted
  List<ExtractedEntity> get people =>
      entities.where((e) => e.type == 'person').toList();

  /// System entities extracted
  List<ExtractedEntity> get systems =>
      entities.where((e) => e.type == 'system').toList();

  /// Company entities extracted
  List<ExtractedEntity> get companies =>
      entities.where((e) => e.type == 'company').toList();

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
  final String? assignee;
  final List<String> relatedEntities;
  final List<String> missingInfo;
  final List<String>? selfServiceSteps;
  final String? ventingResponse;

  /// User can edit before sending
  bool isSelected = true;
  String? editedSummary;
  String? editedRoute;
  String? resolvedAssigneeId;
  String? resolvedAssigneeName;

  ParsedTask({
    required this.position,
    required this.rawChunk,
    required this.summary,
    required this.classification,
    this.system,
    required this.urgency,
    this.deadline,
    this.assignee,
    this.relatedEntities = const [],
    this.missingInfo = const [],
    this.selfServiceSteps,
    this.ventingResponse,
  });

  factory ParsedTask.fromJson(Map<String, dynamic> json) {
    return ParsedTask(
      position: json['position'] ?? 0,
      rawChunk: json['rawChunk'] ?? '',
      summary: json['summary'] ?? '',
      classification: json['classification'] ?? 'task',
      system: json['system'],
      urgency: json['urgency'] ?? 'normal',
      deadline: json['deadline'],
      assignee: json['assignee'],
      relatedEntities: List<String>.from(json['relatedEntities'] ?? []),
      missingInfo: List<String>.from(json['missingInfo'] ?? []),
      selfServiceSteps: json['selfServiceSteps'] != null
          ? List<String>.from(json['selfServiceSteps'])
          : null,
      ventingResponse: json['ventingResponse'],
    );
  }

  /// Has an assignee been identified?
  bool get hasAssignee => assignee != null && assignee!.isNotEmpty;

  /// Display assignee (resolved name or original)
  String get displayAssignee => resolvedAssigneeName ?? assignee ?? '';

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
