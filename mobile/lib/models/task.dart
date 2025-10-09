import 'dart:convert';

class Task {
  final String id;
  final String title;
  final String description;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime? dueDate;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Subtask> subtasks;
  final int plannedPomodoros;
  final int completedPomodoros;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.pending,
    this.dueDate,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.subtasks = const [],
    this.plannedPomodoros = 4,
    this.completedPomodoros = 0,
  });

  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.pending,
    this.dueDate,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.subtasks = const [],
  });

  // Create a new task
  factory Task.create({
    required String title,
    String description = '',
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
    List<String> tags = const [],
    int plannedPomodoros = 4,
  }) {
    final now = DateTime.now();
    return Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      priority: priority,
      dueDate: dueDate,
      tags: tags,
      plannedPomodoros: plannedPomodoros,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Copy with changes
  Task copyWith({
    String? title,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? dueDate,
    List<String>? tags,
    List<Subtask>? subtasks,
    int? plannedPomodoros,
    int? completedPomodoros,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      subtasks: subtasks ?? this.subtasks,
      plannedPomodoros: plannedPomodoros ?? this.plannedPomodoros,
      completedPomodoros: completedPomodoros ?? this.completedPomodoros,
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority.name,
      'status': status.name,
      'dueDate': dueDate?.toIso8601String(),
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'subtasks': subtasks.map((s) => s.toJson()).toList(),
      'plannedPomodoros': plannedPomodoros,
      'completedPomodoros': completedPomodoros,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      priority: TaskPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => TaskPriority.medium,
      ),
      status: TaskStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => TaskStatus.pending,
      ),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      subtasks: (json['subtasks'] as List<dynamic>?)
          ?.map((s) => Subtask.fromJson(s))
          .toList() ?? [],
      plannedPomodoros: json['plannedPomodoros'] ?? 4,
      completedPomodoros: json['completedPomodoros'] ?? 0,
    );
  }

  // Factory for API responses (different format)
  factory Task.fromApiJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'].toString(),
      title: json['title'],
      description: json['description'] ?? '',
      priority: _parsePriority(json['priority']),
      status: _parseStatus(json['status']),
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
      subtasks: (json['subtasks'] as List<dynamic>?)
          ?.map((s) => Subtask.fromApiJson(s))
          .toList() ?? [],
    );
  }

  static TaskPriority _parsePriority(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return TaskPriority.high;
      case 'low':
        return TaskPriority.low;
      default:
        return TaskPriority.medium;
    }
  }

  static TaskStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return TaskStatus.completed;
      case 'in_progress':
      case 'inprogress':
        return TaskStatus.inProgress;
      default:
        return TaskStatus.pending;
    }
  }

  // Convert to API format
  Map<String, dynamic> toApiJson() {
    return {
      'title': title,
      'description': description,
      'priority': priority.name,
      'status': status.name,
      'due_date': dueDate?.toIso8601String(),
      'tags': tags,
    };
  }

  // Getters
  bool get isCompleted => status == TaskStatus.completed;
  bool get isOverdue => dueDate != null &&
      dueDate!.isBefore(DateTime.now()) &&
      !isCompleted;

  int get completedSubtasks => subtasks.where((s) => s.isCompleted).length;
  double get progress => subtasks.isEmpty ? 0.0 : completedSubtasks / subtasks.length;

  String get priorityEmoji {
    switch (priority) {
      case TaskPriority.high:
        return '🔴';
      case TaskPriority.medium:
        return '🟡';
      case TaskPriority.low:
        return '🟢';
    }
  }

  String get statusEmoji {
    switch (status) {
      case TaskStatus.pending:
        return '⏳';
      case TaskStatus.inProgress:
        return '🚀';
      case TaskStatus.completed:
        return '✅';
    }
  }
}

class Subtask {
  final String id;
  final String title;
  final bool isCompleted;
  final DateTime createdAt;

  Subtask({
    required this.id,
    required this.title,
    this.isCompleted = false,
    required this.createdAt,
  });

  factory Subtask.create(String title) {
    return Subtask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      createdAt: DateTime.now(),
    );
  }

  Subtask copyWith({
    String? title,
    bool? isCompleted,
  }) {
    return Subtask(
      id: id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Subtask.fromJson(Map<String, dynamic> json) {
    return Subtask(
      id: json['id'],
      title: json['title'],
      isCompleted: json['isCompleted'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  factory Subtask.fromApiJson(Map<String, dynamic> json) {
    return Subtask(
      id: json['id'].toString(),
      title: json['title'],
      isCompleted: json['completed'] ?? json['is_completed'] ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }
}

enum TaskPriority {
  high,
  medium,
  low;

  String get displayName {
    switch (this) {
      case TaskPriority.high:
        return '高';
      case TaskPriority.medium:
        return '中';
      case TaskPriority.low:
        return '低';
    }
  }
}

enum TaskStatus {
  pending,
  inProgress,
  completed;

  String get displayName {
    switch (this) {
      case TaskStatus.pending:
        return '待开始';
      case TaskStatus.inProgress:
        return '进行中';
      case TaskStatus.completed:
        return '已完成';
    }
  }
}