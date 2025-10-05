import 'dart:convert';
import 'dart:io';

class ApiService {
  static const String _baseUrl = 'http://localhost:8081';

  static Future<String> _makeRequest(String method, String path, {Map<String, dynamic>? body}) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$_baseUrl$path');
      HttpClientRequest request;

      switch (method) {
        case 'GET':
          request = await client.getUrl(uri);
          break;
        case 'POST':
          request = await client.postUrl(uri);
          break;
        case 'PUT':
          request = await client.putUrl(uri);
          break;
        default:
          throw Exception('Unsupported method: $method');
      }

      request.headers.set('Content-Type', 'application/json');

      if (body != null) {
        final bodyString = json.encode(body);
        request.write(bodyString);
      }

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseBody;
      } else {
        throw Exception('HTTP ${response.statusCode}: $responseBody');
      }
    } finally {
      client.close();
    }
  }

  // Get all tasks
  static Future<List<Task>> getTasks() async {
    try {
      final responseBody = await _makeRequest('GET', '/v1/tasks/');
      final data = json.decode(responseBody);
      final List<dynamic> tasksJson = data['data'];
      return tasksJson.map((json) => Task.fromJson(json)).toList();
    } catch (e) {
      print('Error getting tasks: $e');
      return [];
    }
  }

  // Create a new task
  static Future<Task?> createTask({
    required String title,
    String? description,
    String priority = 'medium',
    DateTime? dueDate,
  }) async {
    try {
      final taskData = {
        'title': title,
        'description': description,
        'priority': priority,
        'due_date': dueDate?.toIso8601String(),
      };

      final responseBody = await _makeRequest('POST', '/v1/tasks/', body: taskData);
      final data = json.decode(responseBody);
      return Task.fromJson(data['data']);
    } catch (e) {
      print('Error creating task: $e');
      return null;
    }
  }

  // Update task status
  static Future<bool> updateTaskStatus(String taskId, String status) async {
    try {
      final responseBody = await _makeRequest('PUT', '/v1/tasks/$taskId', body: {'status': status});
      return true;
    } catch (e) {
      print('Error updating task: $e');
      return false;
    }
  }

  // Update task (full update)
  static Future<Task?> updateTask(String taskId, {
    String? title,
    String? description,
    String? priority,
    String? status,
    DateTime? dueDate,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (priority != null) updateData['priority'] = priority;
      if (status != null) updateData['status'] = status;
      if (dueDate != null) updateData['due_date'] = dueDate.toIso8601String();

      final responseBody = await _makeRequest('PUT', '/v1/tasks/$taskId', body: updateData);
      final data = json.decode(responseBody);
      return Task.fromJson(data['data']);
    } catch (e) {
      print('Error updating task: $e');
      return null;
    }
  }

  // Delete task
  static Future<bool> deleteTask(String taskId) async {
    try {
      final responseBody = await _makeRequest('DELETE', '/v1/tasks/$taskId');
      return true;
    } catch (e) {
      print('Error deleting task: $e');
      return false;
    }
  }

  // Start a pomodoro session
  static Future<PomodoroSession?> startSession({
    String? taskId,
    String type = 'work',
    int duration = 1500, // 25 minutes in seconds
  }) async {
    try {
      final sessionData = {
        'task_id': taskId,
        'type': type,
        'duration': duration,
      };

      final responseBody = await _makeRequest('POST', '/v1/pomodoro/sessions/', body: sessionData);
      final data = json.decode(responseBody);
      return PomodoroSession.fromJson(data['data']);
    } catch (e) {
      print('Error starting session: $e');
      return null;
    }
  }

  // Update session status
  static Future<bool> updateSession(
    String sessionId, {
    String? status,
    int? remainingTime,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (status != null) updateData['status'] = status;
      if (remainingTime != null) updateData['remaining_time'] = remainingTime;

      final responseBody = await _makeRequest('PUT', '/v1/pomodoro/sessions/$sessionId', body: updateData);
      return true;
    } catch (e) {
      print('Error updating session: $e');
      return false;
    }
  }

  // Get analytics data
  static Future<AnalyticsData?> getAnalytics() async {
    try {
      final responseBody = await _makeRequest('GET', '/v1/reports/analytics');
      final data = json.decode(responseBody);
      return AnalyticsData.fromJson(data['data']);
    } catch (e) {
      print('Error getting analytics: $e');
      return null;
    }
  }
}

// Data models
class Task {
  final String id;
  final String title;
  final String? description;
  final String priority;
  final String status;
  final DateTime? dueDate;
  final List<Subtask> subtasks;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.priority,
    required this.status,
    this.dueDate,
    this.subtasks = const [],
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      priority: json['priority'],
      status: json['status'],
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      subtasks: json['subtasks'] != null
          ? (json['subtasks'] as List).map((s) => Subtask.fromJson(s)).toList()
          : [],
    );
  }
}

class Subtask {
  final String id;
  final String title;
  final bool completed;

  Subtask({
    required this.id,
    required this.title,
    required this.completed,
  });

  factory Subtask.fromJson(Map<String, dynamic> json) {
    return Subtask(
      id: json['id'],
      title: json['title'],
      completed: json['completed'],
    );
  }
}

class PomodoroSession {
  final String id;
  final String? taskId;
  final String type;
  final int duration;
  final DateTime startedAt;
  final String status;
  final int remainingTime;

  PomodoroSession({
    required this.id,
    this.taskId,
    required this.type,
    required this.duration,
    required this.startedAt,
    required this.status,
    required this.remainingTime,
  });

  factory PomodoroSession.fromJson(Map<String, dynamic> json) {
    return PomodoroSession(
      id: json['id'],
      taskId: json['task_id'],
      type: json['type'],
      duration: json['duration'],
      startedAt: DateTime.parse(json['started_at']),
      status: json['status'],
      remainingTime: json['remaining_time'],
    );
  }
}

class AnalyticsData {
  final DailyStats today;
  final WeeklyStats thisWeek;

  AnalyticsData({
    required this.today,
    required this.thisWeek,
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> json) {
    return AnalyticsData(
      today: DailyStats.fromJson(json['today']),
      thisWeek: WeeklyStats.fromJson(json['this_week']),
    );
  }
}

class DailyStats {
  final int sessionsCompleted;
  final int focusTime;
  final int tasksCompleted;

  DailyStats({
    required this.sessionsCompleted,
    required this.focusTime,
    required this.tasksCompleted,
  });

  factory DailyStats.fromJson(Map<String, dynamic> json) {
    return DailyStats(
      sessionsCompleted: json['sessions_completed'],
      focusTime: json['focus_time'],
      tasksCompleted: json['tasks_completed'],
    );
  }
}

class WeeklyStats {
  final int sessionsCompleted;
  final int focusTime;
  final int tasksCompleted;

  WeeklyStats({
    required this.sessionsCompleted,
    required this.focusTime,
    required this.tasksCompleted,
  });

  factory WeeklyStats.fromJson(Map<String, dynamic> json) {
    return WeeklyStats(
      sessionsCompleted: json['sessions_completed'],
      focusTime: json['focus_time'],
      tasksCompleted: json['tasks_completed'],
    );
  }
}