import 'dart:convert';

class PomodoroSession {
  final String id;
  final String? taskId;
  final String? taskTitle;
  final DateTime startTime;
  final DateTime? endTime;
  final int plannedDuration; // 计划时长（秒）
  final int actualDuration; // 实际时长（秒）
  final SessionStatus status;
  final String? notes; // 会话结束时的备注
  final SessionType type; // 工作时间、短休息、长休息

  PomodoroSession({
    required this.id,
    this.taskId,
    this.taskTitle,
    required this.startTime,
    this.endTime,
    required this.plannedDuration,
    required this.actualDuration,
    required this.status,
    this.notes,
    required this.type,
  });

  factory PomodoroSession.create({
    String? taskId,
    String? taskTitle,
    required int plannedDuration,
    SessionType type = SessionType.work,
  }) {
    return PomodoroSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      taskId: taskId,
      taskTitle: taskTitle,
      startTime: DateTime.now(),
      plannedDuration: plannedDuration,
      actualDuration: 0,
      status: SessionStatus.active,
      type: type,
    );
  }

  PomodoroSession copyWith({
    String? taskId,
    String? taskTitle,
    DateTime? startTime,
    DateTime? endTime,
    int? plannedDuration,
    int? actualDuration,
    SessionStatus? status,
    String? notes,
    SessionType? type,
  }) {
    return PomodoroSession(
      id: id,
      taskId: taskId ?? this.taskId,
      taskTitle: taskTitle ?? this.taskTitle,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      plannedDuration: plannedDuration ?? this.plannedDuration,
      actualDuration: actualDuration ?? this.actualDuration,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      type: type ?? this.type,
    );
  }

  // JSON序列化
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'taskTitle': taskTitle,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'plannedDuration': plannedDuration,
      'actualDuration': actualDuration,
      'status': status.name,
      'notes': notes,
      'type': type.name,
    };
  }

  factory PomodoroSession.fromJson(Map<String, dynamic> json) {
    return PomodoroSession(
      id: json['id'],
      taskId: json['taskId'],
      taskTitle: json['taskTitle'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      plannedDuration: json['plannedDuration'],
      actualDuration: json['actualDuration'],
      status: SessionStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => SessionStatus.active,
      ),
      notes: json['notes'],
      type: SessionType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => SessionType.work,
      ),
    );
  }

  // Factory for API responses
  factory PomodoroSession.fromApiJson(Map<String, dynamic> json) {
    return PomodoroSession(
      id: json['id'].toString(),
      taskId: json['task_id']?.toString(),
      taskTitle: json['task_title'],
      startTime: json['start_time'] != null ? DateTime.parse(json['start_time']) : DateTime.now(),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      plannedDuration: json['planned_duration'] ?? json['duration'] ?? 1500,
      actualDuration: json['actual_duration'] ?? 0,
      status: _parseApiStatus(json['status']),
      notes: json['notes'],
      type: _parseApiType(json['type']),
    );
  }

  static SessionStatus _parseApiStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return SessionStatus.completed;
      case 'interrupted':
        return SessionStatus.interrupted;
      case 'paused':
        return SessionStatus.paused;
      default:
        return SessionStatus.active;
    }
  }

  static SessionType _parseApiType(String? type) {
    switch (type?.toLowerCase()) {
      case 'short_break':
      case 'shortbreak':
        return SessionType.shortBreak;
      case 'long_break':
      case 'longbreak':
        return SessionType.longBreak;
      default:
        return SessionType.work;
    }
  }

  // Convert to API format
  Map<String, dynamic> toApiJson() {
    return {
      'task_id': taskId,
      'task_title': taskTitle,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'planned_duration': plannedDuration,
      'actual_duration': actualDuration,
      'status': status.name,
      'notes': notes,
      'type': type.name,
    };
  }

  // 获取方法
  bool get isCompleted => status == SessionStatus.completed;
  bool get isActive => status == SessionStatus.active;
  bool get isInterrupted => status == SessionStatus.interrupted;

  Duration get duration =>
      endTime != null ? endTime!.difference(startTime) : Duration.zero;

  double get completionRate {
    if (plannedDuration == 0) return 0.0;
    return (actualDuration / plannedDuration).clamp(0.0, 1.0);
  }

  String get statusEmoji {
    switch (status) {
      case SessionStatus.active:
        return '🟡';
      case SessionStatus.completed:
        return '✅';
      case SessionStatus.interrupted:
        return '🛑';
      case SessionStatus.paused:
        return '⏸️';
    }
  }

  String get typeEmoji {
    switch (type) {
      case SessionType.work:
        return '🍅';
      case SessionType.shortBreak:
        return '☕';
      case SessionType.longBreak:
        return '🛋️';
    }
  }

  String get durationDisplay {
    int minutes = actualDuration ~/ 60;
    int seconds = actualDuration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get plannedDurationDisplay {
    int minutes = plannedDuration ~/ 60;
    int seconds = plannedDuration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

enum SessionStatus {
  active,
  completed,
  interrupted,
  paused;

  String get displayName {
    switch (this) {
      case SessionStatus.active:
        return '进行中';
      case SessionStatus.completed:
        return '已完成';
      case SessionStatus.interrupted:
        return '已中断';
      case SessionStatus.paused:
        return '已暂停';
    }
  }
}

enum SessionType {
  work,
  shortBreak,
  longBreak;

  String get displayName {
    switch (this) {
      case SessionType.work:
        return '工作时间';
      case SessionType.shortBreak:
        return '短休息';
      case SessionType.longBreak:
        return '长休息';
    }
  }

  String get emoji {
    switch (this) {
      case SessionType.work:
        return '🍅';
      case SessionType.shortBreak:
        return '☕';
      case SessionType.longBreak:
        return '🛋️';
    }
  }
}

// 会话统计类
class SessionStatistics {
  final int totalSessions;
  final int completedSessions;
  final int interruptedSessions;
  final Duration totalFocusTime;
  final Duration averageSessionTime;
  final double completionRate;
  final int todaySessions;
  final Duration todayFocusTime;

  SessionStatistics({
    required this.totalSessions,
    required this.completedSessions,
    required this.interruptedSessions,
    required this.totalFocusTime,
    required this.averageSessionTime,
    required this.completionRate,
    required this.todaySessions,
    required this.todayFocusTime,
  });

  String get totalFocusTimeDisplay {
    int hours = totalFocusTime.inHours;
    int minutes = totalFocusTime.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String get todayFocusTimeDisplay {
    int hours = todayFocusTime.inHours;
    int minutes = todayFocusTime.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String get averageSessionTimeDisplay {
    int minutes = averageSessionTime.inMinutes;
    int seconds = averageSessionTime.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }
}