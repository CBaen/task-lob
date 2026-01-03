/// Task model representing a parsed task from a lob
class Task {
  final String id;
  final String rawInput;
  final String? lobSessionId;
  final int? positionInLob;
  final TaskClassification classification;
  final TaskUrgency urgency;
  final DateTime? deadline;
  final String? systemName;
  final String summary;
  final String? currentState;
  final String? desiredOutcome;
  final List<String> missingInfo;
  final String senderId;
  final String? ownerId;
  final String? courtUserId;
  final String? courtReason;
  final TaskStatus status;
  final Map<String, dynamic>? aiResearch;
  final Map<String, dynamic>? aiSuggestedPlan;
  final Map<String, dynamic>? contextInjected;
  final String? resolutionNotes;
  final String workspaceId;
  final DateTime created;
  final DateTime updated;

  Task({
    required this.id,
    required this.rawInput,
    this.lobSessionId,
    this.positionInLob,
    required this.classification,
    required this.urgency,
    this.deadline,
    this.systemName,
    required this.summary,
    this.currentState,
    this.desiredOutcome,
    this.missingInfo = const [],
    required this.senderId,
    this.ownerId,
    this.courtUserId,
    this.courtReason,
    required this.status,
    this.aiResearch,
    this.aiSuggestedPlan,
    this.contextInjected,
    this.resolutionNotes,
    required this.workspaceId,
    required this.created,
    required this.updated,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      rawInput: json['raw_input'],
      lobSessionId: json['lob_session'],
      positionInLob: json['position_in_lob'],
      classification: TaskClassification.fromString(json['classification']),
      urgency: TaskUrgency.fromString(json['urgency']),
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      systemName: json['system_name'],
      summary: json['summary'],
      currentState: json['current_state'],
      desiredOutcome: json['desired_outcome'],
      missingInfo: List<String>.from(json['missing_info'] ?? []),
      senderId: json['sender'],
      ownerId: json['owner'],
      courtUserId: json['court_user'],
      courtReason: json['court_reason'],
      status: TaskStatus.fromString(json['status']),
      aiResearch: json['ai_research'],
      aiSuggestedPlan: json['ai_suggested_plan'],
      contextInjected: json['context_injected'],
      resolutionNotes: json['resolution_notes'],
      workspaceId: json['workspace'],
      created: DateTime.parse(json['created']),
      updated: DateTime.parse(json['updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'raw_input': rawInput,
      'lob_session': lobSessionId,
      'position_in_lob': positionInLob,
      'classification': classification.value,
      'urgency': urgency.value,
      'deadline': deadline?.toIso8601String(),
      'system_name': systemName,
      'summary': summary,
      'current_state': currentState,
      'desired_outcome': desiredOutcome,
      'missing_info': missingInfo,
      'sender': senderId,
      'owner': ownerId,
      'court_user': courtUserId,
      'court_reason': courtReason,
      'status': status.value,
      'ai_research': aiResearch,
      'ai_suggested_plan': aiSuggestedPlan,
      'context_injected': contextInjected,
      'resolution_notes': resolutionNotes,
      'workspace': workspaceId,
    };
  }

  /// Is this task in my court? (I need to act)
  bool isInMyCourt(String myUserId) => courtUserId == myUserId;

  /// Is this task waiting on someone else?
  bool isWaitingOnOthers(String myUserId) =>
      courtUserId != null && courtUserId != myUserId;

  /// Can this be self-serviced?
  bool get isSelfService => classification == TaskClassification.selfService;

  /// Is this just venting?
  bool get isVenting => classification == TaskClassification.venting;

  /// Does this need more info?
  bool get needsMoreInfo => missingInfo.isNotEmpty;
}

enum TaskClassification {
  task('task'),
  selfService('self_service'),
  reminder('reminder'),
  venting('venting');

  final String value;
  const TaskClassification(this.value);

  static TaskClassification fromString(String value) {
    return TaskClassification.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TaskClassification.task,
    );
  }
}

enum TaskUrgency {
  normal('normal'),
  urgent('urgent'),
  deadline('deadline');

  final String value;
  const TaskUrgency(this.value);

  static TaskUrgency fromString(String value) {
    return TaskUrgency.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TaskUrgency.normal,
    );
  }
}

enum TaskStatus {
  draft('draft'),
  sent('sent'),
  active('active'),
  blocked('blocked'),
  done('done');

  final String value;
  const TaskStatus(this.value);

  static TaskStatus fromString(String value) {
    return TaskStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TaskStatus.draft,
    );
  }
}
