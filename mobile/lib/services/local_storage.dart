import 'dart:convert';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

class LocalStorage {
  static LocalStorage? _instance;
  static LocalStorage get instance => _instance ??= LocalStorage._();

  LocalStorage._();

  static const String _userBox = 'user';
  static const String _authBox = 'auth';
  static const String _tasksBox = 'tasks';
  static const String _subtasksBox = 'subtasks';
  static const String _pomodoroBox = 'pomodoro';
  static const String _notesBox = 'notes';
  static const String _remindersBox = 'reminders';
  static const String _reportsBox = 'reports';
  static const String _settingsBox = 'settings';
  static const String _offlineQueueBox = 'offline_queue';
  static const String _syncStateBox = 'sync_state';

  late Box _userBoxInstance;
  late Box _authBoxInstance;
  late Box _tasksBoxInstance;
  late Box _subtasksBoxInstance;
  late Box _pomodoroBoxInstance;
  late Box _notesBoxInstance;
  late Box _remindersBoxInstance;
  late Box _reportsBoxInstance;
  late Box _settingsBoxInstance;
  late Box _offlineQueueBoxInstance;
  late Box _syncStateBoxInstance;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await Hive.initFlutter();

    // Initialize all boxes
    _userBoxInstance = await Hive.openBox(_userBox);
    _authBoxInstance = await Hive.openBox(_authBox);
    _tasksBoxInstance = await Hive.openBox(_tasksBox);
    _subtasksBoxInstance = await Hive.openBox(_subtasksBox);
    _pomodoroBoxInstance = await Hive.openBox(_pomodoroBox);
    _notesBoxInstance = await Hive.openBox(_notesBox);
    _remindersBoxInstance = await Hive.openBox(_remindersBox);
    _reportsBoxInstance = await Hive.openBox(_reportsBox);
    _settingsBoxInstance = await Hive.openBox(_settingsBox);
    _offlineQueueBoxInstance = await Hive.openBox(_offlineQueueBox);
    _syncStateBoxInstance = await Hive.openBox(_syncStateBox);

    _isInitialized = true;
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('LocalStorage not initialized. Call initialize() first.');
    }
  }

  // Auth Token Management
  Future<void> saveAuthToken(String token) async {
    _ensureInitialized();
    await _authBoxInstance.put('access_token', token);
  }

  Future<void> saveRefreshToken(String token) async {
    _ensureInitialized();
    await _authBoxInstance.put('refresh_token', token);
  }

  String? getAuthToken() {
    _ensureInitialized();
    return _authBoxInstance.get('access_token');
  }

  String? getRefreshToken() {
    _ensureInitialized();
    return _authBoxInstance.get('refresh_token');
  }

  Future<void> clearAuthTokens() async {
    _ensureInitialized();
    await _authBoxInstance.delete('access_token');
    await _authBoxInstance.delete('refresh_token');
  }

  // User Data Management
  Future<void> saveUser(Map<String, dynamic> userData) async {
    _ensureInitialized();
    await _userBoxInstance.put('current_user', jsonEncode(userData));
  }

  Map<String, dynamic>? getUser() {
    _ensureInitialized();
    final userStr = _userBoxInstance.get('current_user');
    if (userStr != null) {
      return jsonDecode(userStr);
    }
    return null;
  }

  Future<void> clearUser() async {
    _ensureInitialized();
    await _userBoxInstance.delete('current_user');
  }

  // Tasks Management
  Future<void> saveTask(String taskId, Map<String, dynamic> taskData) async {
    _ensureInitialized();
    await _tasksBoxInstance.put(taskId, jsonEncode(taskData));
  }

  Future<void> saveTasks(List<Map<String, dynamic>> tasks) async {
    _ensureInitialized();
    final Map<String, String> tasksMap = {};
    for (final task in tasks) {
      tasksMap[task['id']] = jsonEncode(task);
    }
    await _tasksBoxInstance.putAll(tasksMap);
  }

  Map<String, dynamic>? getTask(String taskId) {
    _ensureInitialized();
    final taskStr = _tasksBoxInstance.get(taskId);
    if (taskStr != null) {
      return jsonDecode(taskStr);
    }
    return null;
  }

  List<Map<String, dynamic>> getAllTasks() {
    _ensureInitialized();
    final List<Map<String, dynamic>> tasks = [];
    for (final key in _tasksBoxInstance.keys) {
      final taskStr = _tasksBoxInstance.get(key);
      if (taskStr != null) {
        tasks.add(jsonDecode(taskStr));
      }
    }
    return tasks;
  }

  Future<void> deleteTask(String taskId) async {
    _ensureInitialized();
    await _tasksBoxInstance.delete(taskId);
  }

  Future<void> clearAllTasks() async {
    _ensureInitialized();
    await _tasksBoxInstance.clear();
  }

  // Subtasks Management
  Future<void> saveSubtask(String subtaskId, Map<String, dynamic> subtaskData) async {
    _ensureInitialized();
    await _subtasksBoxInstance.put(subtaskId, jsonEncode(subtaskData));
  }

  Future<void> saveSubtasks(List<Map<String, dynamic>> subtasks) async {
    _ensureInitialized();
    final Map<String, String> subtasksMap = {};
    for (final subtask in subtasks) {
      subtasksMap[subtask['id']] = jsonEncode(subtask);
    }
    await _subtasksBoxInstance.putAll(subtasksMap);
  }

  List<Map<String, dynamic>> getSubtasksForTask(String taskId) {
    _ensureInitialized();
    final List<Map<String, dynamic>> subtasks = [];
    for (final key in _subtasksBoxInstance.keys) {
      final subtaskStr = _subtasksBoxInstance.get(key);
      if (subtaskStr != null) {
        final subtask = jsonDecode(subtaskStr);
        if (subtask['task_id'] == taskId) {
          subtasks.add(subtask);
        }
      }
    }
    return subtasks;
  }

  Future<void> deleteSubtask(String subtaskId) async {
    _ensureInitialized();
    await _subtasksBoxInstance.delete(subtaskId);
  }

  // Pomodoro Sessions Management
  Future<void> savePomodoroSession(String sessionId, Map<String, dynamic> sessionData) async {
    _ensureInitialized();
    await _pomodoroBoxInstance.put(sessionId, jsonEncode(sessionData));
  }

  Future<void> savePomodoroSessions(List<Map<String, dynamic>> sessions) async {
    _ensureInitialized();
    final Map<String, String> sessionsMap = {};
    for (final session in sessions) {
      sessionsMap[session['id']] = jsonEncode(session);
    }
    await _pomodoroBoxInstance.putAll(sessionsMap);
  }

  List<Map<String, dynamic>> getPomodoroSessionsForTask(String taskId) {
    _ensureInitialized();
    final List<Map<String, dynamic>> sessions = [];
    for (final key in _pomodoroBoxInstance.keys) {
      final sessionStr = _pomodoroBoxInstance.get(key);
      if (sessionStr != null) {
        final session = jsonDecode(sessionStr);
        if (session['task_id'] == taskId) {
          sessions.add(session);
        }
      }
    }
    return sessions;
  }

  List<Map<String, dynamic>> getAllPomodoroSessions() {
    _ensureInitialized();
    final List<Map<String, dynamic>> sessions = [];
    for (final key in _pomodoroBoxInstance.keys) {
      final sessionStr = _pomodoroBoxInstance.get(key);
      if (sessionStr != null) {
        sessions.add(jsonDecode(sessionStr));
      }
    }
    return sessions;
  }

  Future<void> deletePomodoroSession(String sessionId) async {
    _ensureInitialized();
    await _pomodoroBoxInstance.delete(sessionId);
  }

  // Notes Management
  Future<void> saveNote(String noteId, Map<String, dynamic> noteData) async {
    _ensureInitialized();
    await _notesBoxInstance.put(noteId, jsonEncode(noteData));
  }

  List<Map<String, dynamic>> getNotesForTask(String taskId) {
    _ensureInitialized();
    final List<Map<String, dynamic>> notes = [];
    for (final key in _notesBoxInstance.keys) {
      final noteStr = _notesBoxInstance.get(key);
      if (noteStr != null) {
        final note = jsonDecode(noteStr);
        if (note['task_id'] == taskId) {
          notes.add(note);
        }
      }
    }
    return notes;
  }

  Future<void> deleteNote(String noteId) async {
    _ensureInitialized();
    await _notesBoxInstance.delete(noteId);
  }

  // Reminders Management
  Future<void> saveReminder(String reminderId, Map<String, dynamic> reminderData) async {
    _ensureInitialized();
    await _remindersBoxInstance.put(reminderId, jsonEncode(reminderData));
  }

  List<Map<String, dynamic>> getRemindersForTask(String taskId) {
    _ensureInitialized();
    final List<Map<String, dynamic>> reminders = [];
    for (final key in _remindersBoxInstance.keys) {
      final reminderStr = _remindersBoxInstance.get(key);
      if (reminderStr != null) {
        final reminder = jsonDecode(reminderStr);
        if (reminder['task_id'] == taskId) {
          reminders.add(reminder);
        }
      }
    }
    return reminders;
  }

  List<Map<String, dynamic>> getActiveReminders() {
    _ensureInitialized();
    final List<Map<String, dynamic>> reminders = [];
    final now = DateTime.now().toIso8601String();

    for (final key in _remindersBoxInstance.keys) {
      final reminderStr = _remindersBoxInstance.get(key);
      if (reminderStr != null) {
        final reminder = jsonDecode(reminderStr);
        if (reminder['scheduled_at'] != null &&
            DateTime.parse(reminder['scheduled_at']).isAfter(DateTime.now()) &&
            reminder['status'] == 'active') {
          reminders.add(reminder);
        }
      }
    }
    return reminders;
  }

  Future<void> deleteReminder(String reminderId) async {
    _ensureInitialized();
    await _remindersBoxInstance.delete(reminderId);
  }

  // Reports Cache Management
  Future<void> saveReport(String reportKey, Map<String, dynamic> reportData) async {
    _ensureInitialized();
    final cacheEntry = {
      'data': reportData,
      'cached_at': DateTime.now().toIso8601String(),
      'expires_at': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
    };
    await _reportsBoxInstance.put(reportKey, jsonEncode(cacheEntry));
  }

  Map<String, dynamic>? getCachedReport(String reportKey) {
    _ensureInitialized();
    final cacheEntryStr = _reportsBoxInstance.get(reportKey);
    if (cacheEntryStr != null) {
      final cacheEntry = jsonDecode(cacheEntryStr);
      final expiresAt = DateTime.parse(cacheEntry['expires_at']);
      if (expiresAt.isAfter(DateTime.now())) {
        return cacheEntry['data'];
      } else {
        // Remove expired cache
        _reportsBoxInstance.delete(reportKey);
      }
    }
    return null;
  }

  Future<void> clearExpiredReports() async {
    _ensureInitialized();
    final keysToDelete = <String>[];
    final now = DateTime.now();

    for (final key in _reportsBoxInstance.keys) {
      final cacheEntryStr = _reportsBoxInstance.get(key);
      if (cacheEntryStr != null) {
        final cacheEntry = jsonDecode(cacheEntryStr);
        final expiresAt = DateTime.parse(cacheEntry['expires_at']);
        if (expiresAt.isBefore(now)) {
          keysToDelete.add(key);
        }
      }
    }

    for (final key in keysToDelete) {
      await _reportsBoxInstance.delete(key);
    }
  }

  // Settings Management
  Future<void> saveSetting(String key, dynamic value) async {
    _ensureInitialized();
    await _settingsBoxInstance.put(key, value);
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    _ensureInitialized();
    await _settingsBoxInstance.putAll(settings);
  }

  T? getSetting<T>(String key, [T? defaultValue]) {
    _ensureInitialized();
    return _settingsBoxInstance.get(key, defaultValue: defaultValue);
  }

  Map<String, dynamic> getAllSettings() {
    _ensureInitialized();
    return Map<String, dynamic>.from(_settingsBoxInstance.toMap());
  }

  Future<void> deleteSetting(String key) async {
    _ensureInitialized();
    await _settingsBoxInstance.delete(key);
  }

  // Offline Queue Management
  Future<void> addToOfflineQueue(Map<String, dynamic> operation) async {
    _ensureInitialized();
    final queueId = '${DateTime.now().millisecondsSinceEpoch}_${operation['method']}_${operation['path']?.replaceAll('/', '_')}';
    final queueItem = {
      ...operation,
      'id': queueId,
      'created_at': DateTime.now().toIso8601String(),
      'retry_count': 0,
      'status': 'pending', // pending, processing, completed, failed
    };
    await _offlineQueueBoxInstance.put(queueId, jsonEncode(queueItem));
  }

  List<Map<String, dynamic>> getOfflineQueue() {
    _ensureInitialized();
    final List<Map<String, dynamic>> queue = [];
    for (final key in _offlineQueueBoxInstance.keys) {
      final itemStr = _offlineQueueBoxInstance.get(key);
      if (itemStr != null) {
        queue.add(jsonDecode(itemStr));
      }
    }

    // Sort by creation time
    queue.sort((a, b) => DateTime.parse(a['created_at']).compareTo(DateTime.parse(b['created_at'])));
    return queue;
  }

  Future<void> updateOfflineQueueItem(String queueId, Map<String, dynamic> updates) async {
    _ensureInitialized();
    final itemStr = _offlineQueueBoxInstance.get(queueId);
    if (itemStr != null) {
      final item = jsonDecode(itemStr);
      item.addAll(updates);
      await _offlineQueueBoxInstance.put(queueId, jsonEncode(item));
    }
  }

  Future<void> removeFromOfflineQueue(String queueId) async {
    _ensureInitialized();
    await _offlineQueueBoxInstance.delete(queueId);
  }

  Future<void> clearOfflineQueue() async {
    _ensureInitialized();
    await _offlineQueueBoxInstance.clear();
  }

  // Sync State Management
  Future<void> saveLastSyncTime(String entity, DateTime syncTime) async {
    _ensureInitialized();
    await _syncStateBoxInstance.put('${entity}_last_sync', syncTime.toIso8601String());
  }

  DateTime? getLastSyncTime(String entity) {
    _ensureInitialized();
    final syncTimeStr = _syncStateBoxInstance.get('${entity}_last_sync');
    if (syncTimeStr != null) {
      return DateTime.parse(syncTimeStr);
    }
    return null;
  }

  Future<void> saveSyncToken(String entity, String token) async {
    _ensureInitialized();
    await _syncStateBoxInstance.put('${entity}_sync_token', token);
  }

  String? getSyncToken(String entity) {
    _ensureInitialized();
    return _syncStateBoxInstance.get('${entity}_sync_token');
  }

  Future<void> saveConflictResolution(String entityId, String resolution, Map<String, dynamic> data) async {
    _ensureInitialized();
    final conflictData = {
      'entity_id': entityId,
      'resolution': resolution, // local_wins, remote_wins, merged
      'resolved_at': DateTime.now().toIso8601String(),
      'data': data,
    };
    await _syncStateBoxInstance.put('conflict_$entityId', jsonEncode(conflictData));
  }

  Map<String, dynamic>? getConflictResolution(String entityId) {
    _ensureInitialized();
    final conflictStr = _syncStateBoxInstance.get('conflict_$entityId');
    if (conflictStr != null) {
      return jsonDecode(conflictStr);
    }
    return null;
  }

  // Data Cleanup and Maintenance
  Future<void> clearAllData() async {
    _ensureInitialized();
    await Future.wait([
      _userBoxInstance.clear(),
      _authBoxInstance.clear(),
      _tasksBoxInstance.clear(),
      _subtasksBoxInstance.clear(),
      _pomodoroBoxInstance.clear(),
      _notesBoxInstance.clear(),
      _remindersBoxInstance.clear(),
      _reportsBoxInstance.clear(),
      _settingsBoxInstance.clear(),
      _offlineQueueBoxInstance.clear(),
      _syncStateBoxInstance.clear(),
    ]);
  }

  Future<void> clearUserData() async {
    _ensureInitialized();
    await Future.wait([
      _userBoxInstance.clear(),
      _tasksBoxInstance.clear(),
      _subtasksBoxInstance.clear(),
      _pomodoroBoxInstance.clear(),
      _notesBoxInstance.clear(),
      _remindersBoxInstance.clear(),
      _reportsBoxInstance.clear(),
      _offlineQueueBoxInstance.clear(),
      _syncStateBoxInstance.clear(),
    ]);
  }

  Future<void> cleanup() async {
    _ensureInitialized();

    // Clear expired reports
    await clearExpiredReports();

    // Remove old offline queue items (older than 7 days)
    final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
    final queueItemsToDelete = <String>[];

    for (final key in _offlineQueueBoxInstance.keys) {
      final itemStr = _offlineQueueBoxInstance.get(key);
      if (itemStr != null) {
        final item = jsonDecode(itemStr);
        final createdAt = DateTime.parse(item['created_at']);
        if (createdAt.isBefore(cutoffDate) && item['status'] == 'completed') {
          queueItemsToDelete.add(key);
        }
      }
    }

    for (final key in queueItemsToDelete) {
      await _offlineQueueBoxInstance.delete(key);
    }
  }

  // Storage Info
  Future<Map<String, dynamic>> getStorageInfo() async {
    _ensureInitialized();

    final Directory appDir = await getApplicationDocumentsDirectory();
    final String dbPath = '${appDir.path}/hive';

    int totalSize = 0;
    final Map<String, int> boxSizes = {};

    try {
      final Directory hiveDir = Directory(dbPath);
      if (await hiveDir.exists()) {
        await for (final FileSystemEntity entity in hiveDir.list()) {
          if (entity is File) {
            final size = await entity.length();
            totalSize += size;

            final filename = entity.path.split('/').last;
            if (filename.contains('.hive')) {
              final boxName = filename.split('.').first;
              boxSizes[boxName] = size;
            }
          }
        }
      }
    } catch (e) {
      // Handle directory access errors
    }

    return {
      'total_size_bytes': totalSize,
      'total_size_mb': (totalSize / (1024 * 1024)).toStringAsFixed(2),
      'box_sizes': boxSizes,
      'box_counts': {
        'user': _userBoxInstance.length,
        'auth': _authBoxInstance.length,
        'tasks': _tasksBoxInstance.length,
        'subtasks': _subtasksBoxInstance.length,
        'pomodoro': _pomodoroBoxInstance.length,
        'notes': _notesBoxInstance.length,
        'reminders': _remindersBoxInstance.length,
        'reports': _reportsBoxInstance.length,
        'settings': _settingsBoxInstance.length,
        'offline_queue': _offlineQueueBoxInstance.length,
        'sync_state': _syncStateBoxInstance.length,
      },
    };
  }

  Future<void> dispose() async {
    if (_isInitialized) {
      await Future.wait([
        _userBoxInstance.close(),
        _authBoxInstance.close(),
        _tasksBoxInstance.close(),
        _subtasksBoxInstance.close(),
        _pomodoroBoxInstance.close(),
        _notesBoxInstance.close(),
        _remindersBoxInstance.close(),
        _reportsBoxInstance.close(),
        _settingsBoxInstance.close(),
        _offlineQueueBoxInstance.close(),
        _syncStateBoxInstance.close(),
      ]);
      _isInitialized = false;
    }
  }
}