import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models/index.dart';

class ApiService {
  static const String _baseUrl = 'http://localhost:8081';

  static Future<String> _makeRequest(String method, String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = {'Content-Type': 'application/json'};

    http.Response response;

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: headers,
            body: body != null ? json.encode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: headers,
            body: body != null ? json.encode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers);
          break;
        default:
          throw Exception('Unsupported method: $method');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('API Request failed: $e');
      rethrow;
    }
  }

  // Server connectivity check
  static Future<bool> isServerOnline() async {
    try {
      await _makeRequest('GET', '/health');
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get all tasks
  static Future<List<Task>> getTasks() async {
    try {
      final responseBody = await _makeRequest('GET', '/v1/tasks/');
      final data = json.decode(responseBody);
      final List<dynamic> tasksJson = data['data'] ?? data['tasks'] ?? [];
      return tasksJson.map((json) => Task.fromApiJson(json)).toList();
    } catch (e) {
      print('Error getting tasks: $e');
      return [];
    }
  }

  // Create a new task
  static Future<Task?> createTask(Task task) async {
    try {
      final responseBody = await _makeRequest('POST', '/v1/tasks/', body: task.toApiJson());
      final data = json.decode(responseBody);
      return Task.fromApiJson(data['data'] ?? data);
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
  static Future<Task?> updateTask(Task task) async {
    try {
      final responseBody = await _makeRequest('PUT', '/v1/tasks/${task.id}', body: task.toApiJson());
      final data = json.decode(responseBody);
      return Task.fromApiJson(data['data'] ?? data);
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
  static Future<PomodoroSession?> startSession(PomodoroSession session) async {
    try {
      final sessionData = {
        'task_id': session.taskId,
        'task_title': session.taskTitle,
        'type': session.type.name,
        'planned_duration': session.plannedDuration,
      };

      final responseBody = await _makeRequest('POST', '/v1/pomodoro/sessions/', body: sessionData);
      final data = json.decode(responseBody);
      return PomodoroSession.fromApiJson(data['data'] ?? data);
    } catch (e) {
      print('Error starting session: $e');
      return null;
    }
  }

  // Update session
  static Future<PomodoroSession?> updateSession(PomodoroSession session) async {
    try {
      final responseBody = await _makeRequest('PUT', '/v1/pomodoro/sessions/${session.id}', body: session.toApiJson());
      final data = json.decode(responseBody);
      return PomodoroSession.fromApiJson(data['data'] ?? data);
    } catch (e) {
      print('Error updating session: $e');
      return null;
    }
  }

  // Get session history
  static Future<List<PomodoroSession>> getSessions({String? taskId}) async {
    try {
      String path = '/v1/pomodoro/sessions/';
      if (taskId != null) {
        path += '?task_id=$taskId';
      }

      final responseBody = await _makeRequest('GET', path);
      final data = json.decode(responseBody);
      final List<dynamic> sessionsJson = data['data'] ?? data['sessions'] ?? [];
      return sessionsJson.map((json) => PomodoroSession.fromApiJson(json)).toList();
    } catch (e) {
      print('Error getting sessions: $e');
      return [];
    }
  }

  // Get analytics data
  static Future<Map<String, dynamic>?> getAnalytics() async {
    try {
      final responseBody = await _makeRequest('GET', '/v1/reports/analytics');
      final data = json.decode(responseBody);
      return data['data'] ?? data;
    } catch (e) {
      print('Error getting analytics: $e');
      return null;
    }
  }

  // Sync local data to server
  static Future<bool> syncTasks(List<Task> tasks) async {
    try {
      final tasksData = tasks.map((task) => task.toApiJson()).toList();
      await _makeRequest('POST', '/v1/tasks/sync', body: {'tasks': tasksData});
      return true;
    } catch (e) {
      print('Error syncing tasks: $e');
      return false;
    }
  }

  // Sync local sessions to server
  static Future<bool> syncSessions(List<PomodoroSession> sessions) async {
    try {
      final sessionsData = sessions.map((session) => session.toApiJson()).toList();
      await _makeRequest('POST', '/v1/pomodoro/sessions/sync', body: {'sessions': sessionsData});
      return true;
    } catch (e) {
      print('Error syncing sessions: $e');
      return false;
    }
  }

  // Get server timestamp for sync
  static Future<DateTime?> getServerTime() async {
    try {
      final responseBody = await _makeRequest('GET', '/v1/time');
      final data = json.decode(responseBody);
      return DateTime.parse(data['time']);
    } catch (e) {
      print('Error getting server time: $e');
      return null;
    }
  }

  // Backup user data
  static Future<Map<String, dynamic>?> backupData() async {
    try {
      final responseBody = await _makeRequest('GET', '/v1/user/backup');
      return json.decode(responseBody);
    } catch (e) {
      print('Error backing up data: $e');
      return null;
    }
  }

  // Restore user data
  static Future<bool> restoreData(Map<String, dynamic> backupData) async {
    try {
      await _makeRequest('POST', '/v1/user/restore', body: backupData);
      return true;
    } catch (e) {
      print('Error restoring data: $e');
      return false;
    }
  }
}