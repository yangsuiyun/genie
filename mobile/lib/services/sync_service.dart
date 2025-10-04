import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'local_storage.dart';

enum SyncStatus { idle, syncing, error, completed }

enum ConflictResolution { localWins, remoteWins, merge }

class SyncConflict {
  final String entityId;
  final String entityType;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> remoteData;
  final DateTime localUpdatedAt;
  final DateTime remoteUpdatedAt;

  SyncConflict({
    required this.entityId,
    required this.entityType,
    required this.localData,
    required this.remoteData,
    required this.localUpdatedAt,
    required this.remoteUpdatedAt,
  });

  Map<String, dynamic> toJson() => {
        'entity_id': entityId,
        'entity_type': entityType,
        'local_data': localData,
        'remote_data': remoteData,
        'local_updated_at': localUpdatedAt.toIso8601String(),
        'remote_updated_at': remoteUpdatedAt.toIso8601String(),
      };

  factory SyncConflict.fromJson(Map<String, dynamic> json) => SyncConflict(
        entityId: json['entity_id'],
        entityType: json['entity_type'],
        localData: json['local_data'],
        remoteData: json['remote_data'],
        localUpdatedAt: DateTime.parse(json['local_updated_at']),
        remoteUpdatedAt: DateTime.parse(json['remote_updated_at']),
      );
}

class SyncResult {
  final bool success;
  final int syncedCount;
  final int conflictCount;
  final List<SyncConflict> conflicts;
  final String? error;
  final DateTime syncTime;

  SyncResult({
    required this.success,
    this.syncedCount = 0,
    this.conflictCount = 0,
    this.conflicts = const [],
    this.error,
    required this.syncTime,
  });

  Map<String, dynamic> toJson() => {
        'success': success,
        'synced_count': syncedCount,
        'conflict_count': conflictCount,
        'conflicts': conflicts.map((c) => c.toJson()).toList(),
        'error': error,
        'sync_time': syncTime.toIso8601String(),
      };

  factory SyncResult.fromJson(Map<String, dynamic> json) => SyncResult(
        success: json['success'],
        syncedCount: json['synced_count'] ?? 0,
        conflictCount: json['conflict_count'] ?? 0,
        conflicts: (json['conflicts'] as List?)?.map((c) => SyncConflict.fromJson(c)).toList() ?? [],
        error: json['error'],
        syncTime: DateTime.parse(json['sync_time']),
      );
}

class SyncService {
  static SyncService? _instance;
  static SyncService get instance => _instance ??= SyncService._();

  SyncService._();

  final ApiClient _apiClient = ApiClient.instance;
  final LocalStorage _localStorage = LocalStorage.instance;

  final StreamController<SyncStatus> _statusController = StreamController<SyncStatus>.broadcast();
  final StreamController<SyncResult> _resultController = StreamController<SyncResult>.broadcast();

  Stream<SyncStatus> get statusStream => _statusController.stream;
  Stream<SyncResult> get resultStream => _resultController.stream;

  SyncStatus _currentStatus = SyncStatus.idle;
  SyncStatus get currentStatus => _currentStatus;

  Timer? _periodicSyncTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _autoSyncEnabled = true;
  Duration _syncInterval = const Duration(minutes: 15);

  // Conflict resolution strategy
  ConflictResolution _defaultConflictResolution = ConflictResolution.remoteWins;

  Future<void> initialize() async {
    await _localStorage.initialize();

    // Load sync preferences
    _autoSyncEnabled = _localStorage.getSetting('auto_sync_enabled', true);
    final intervalMinutes = _localStorage.getSetting('sync_interval_minutes', 15);
    _syncInterval = Duration(minutes: intervalMinutes);

    final conflictResolutionStr = _localStorage.getSetting('default_conflict_resolution', 'remote_wins');
    _defaultConflictResolution = ConflictResolution.values.firstWhere(
      (e) => e.toString().split('.').last == conflictResolutionStr,
      orElse: () => ConflictResolution.remoteWins,
    );

    // Setup connectivity monitoring
    _setupConnectivityMonitoring();

    // Start periodic sync if enabled
    if (_autoSyncEnabled) {
      startPeriodicSync();
    }

    // Process any pending offline operations
    await _processOfflineQueue();
  }

  void _setupConnectivityMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final hasConnection = results.any((result) => result != ConnectivityResult.none);

      if (hasConnection && _currentStatus != SyncStatus.syncing) {
        // Connection restored, sync if auto-sync is enabled
        if (_autoSyncEnabled) {
          sync();
        }
        // Process offline queue
        _processOfflineQueue();
      }
    });
  }

  void _updateStatus(SyncStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  void startPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(_syncInterval, (_) => sync());
  }

  void stopPeriodicSync() {
    _periodicSyncTimer?.cancel();
  }

  Future<void> setAutoSyncEnabled(bool enabled) async {
    _autoSyncEnabled = enabled;
    await _localStorage.saveSetting('auto_sync_enabled', enabled);

    if (enabled) {
      startPeriodicSync();
    } else {
      stopPeriodicSync();
    }
  }

  Future<void> setSyncInterval(Duration interval) async {
    _syncInterval = interval;
    await _localStorage.saveSetting('sync_interval_minutes', interval.inMinutes);

    if (_autoSyncEnabled) {
      startPeriodicSync();
    }
  }

  Future<void> setDefaultConflictResolution(ConflictResolution resolution) async {
    _defaultConflictResolution = resolution;
    await _localStorage.saveSetting('default_conflict_resolution', resolution.toString().split('.').last);
  }

  Future<SyncResult> sync({bool forceFullSync = false}) async {
    if (_currentStatus == SyncStatus.syncing) {
      return SyncResult(success: false, error: 'Sync already in progress', syncTime: DateTime.now());
    }

    _updateStatus(SyncStatus.syncing);

    try {
      final result = await _performSync(forceFullSync: forceFullSync);
      _updateStatus(result.success ? SyncStatus.completed : SyncStatus.error);
      _resultController.add(result);
      return result;
    } catch (e) {
      final errorResult = SyncResult(
        success: false,
        error: e.toString(),
        syncTime: DateTime.now(),
      );
      _updateStatus(SyncStatus.error);
      _resultController.add(errorResult);
      return errorResult;
    }
  }

  Future<SyncResult> _performSync({bool forceFullSync = false}) async {
    final syncTime = DateTime.now();
    int totalSynced = 0;
    final List<SyncConflict> allConflicts = [];

    try {
      // Sync each entity type
      final entities = ['tasks', 'subtasks', 'pomodoro_sessions', 'notes', 'reminders'];

      for (final entity in entities) {
        final result = await _syncEntity(entity, forceFullSync: forceFullSync);
        totalSynced += result.syncedCount;
        allConflicts.addAll(result.conflicts);
      }

      // Update last sync time
      await _localStorage.saveLastSyncTime('full_sync', syncTime);

      return SyncResult(
        success: true,
        syncedCount: totalSynced,
        conflictCount: allConflicts.length,
        conflicts: allConflicts,
        syncTime: syncTime,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        error: e.toString(),
        syncTime: syncTime,
      );
    }
  }

  Future<SyncResult> _syncEntity(String entityType, {bool forceFullSync = false}) async {
    final syncTime = DateTime.now();
    int syncedCount = 0;
    final List<SyncConflict> conflicts = [];

    try {
      // Get last sync time for incremental sync
      DateTime? lastSync;
      if (!forceFullSync) {
        lastSync = _localStorage.getLastSyncTime(entityType);
      }

      // Fetch remote changes
      final remoteChanges = await _fetchRemoteChanges(entityType, lastSync);

      // Get local changes
      final localChanges = await _getLocalChanges(entityType, lastSync);

      // Process remote changes and detect conflicts
      for (final remoteItem in remoteChanges) {
        final itemId = remoteItem['id'];
        final localItem = _getLocalItemById(entityType, itemId);

        if (localItem != null) {
          // Check for conflicts
          final localUpdatedAt = DateTime.parse(localItem['updated_at']);
          final remoteUpdatedAt = DateTime.parse(remoteItem['updated_at']);

          if (localUpdatedAt.isAfter(remoteUpdatedAt)) {
            // Local is newer - potential conflict
            final conflict = SyncConflict(
              entityId: itemId,
              entityType: entityType,
              localData: localItem,
              remoteData: remoteItem,
              localUpdatedAt: localUpdatedAt,
              remoteUpdatedAt: remoteUpdatedAt,
            );

            final resolution = await _resolveConflict(conflict);
            if (resolution != null) {
              await _applyConflictResolution(entityType, itemId, resolution);
              syncedCount++;
            } else {
              conflicts.add(conflict);
            }
          } else {
            // Remote is newer or same - apply remote changes
            await _saveLocalItem(entityType, remoteItem);
            syncedCount++;
          }
        } else {
          // New remote item - add locally
          await _saveLocalItem(entityType, remoteItem);
          syncedCount++;
        }
      }

      // Upload local changes that don't conflict
      for (final localItem in localChanges) {
        final itemId = localItem['id'];
        if (!remoteChanges.any((remote) => remote['id'] == itemId)) {
          // Local-only change - upload to server
          await _uploadLocalItem(entityType, localItem);
          syncedCount++;
        }
      }

      // Update sync timestamp
      await _localStorage.saveLastSyncTime(entityType, syncTime);

      return SyncResult(
        success: true,
        syncedCount: syncedCount,
        conflictCount: conflicts.length,
        conflicts: conflicts,
        syncTime: syncTime,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        error: e.toString(),
        syncTime: syncTime,
      );
    }
  }

  Future<List<Map<String, dynamic>>> _fetchRemoteChanges(String entityType, DateTime? since) async {
    final queryParams = <String, dynamic>{};
    if (since != null) {
      queryParams['since'] = since.toIso8601String();
    }

    final response = await _apiClient.get('/sync/$entityType', queryParameters: queryParams);
    if (response.isSuccess) {
      return List<Map<String, dynamic>>.from(response.data['items'] ?? []);
    }
    throw Exception('Failed to fetch remote changes: ${response.error}');
  }

  Future<List<Map<String, dynamic>>> _getLocalChanges(String entityType, DateTime? since) async {
    switch (entityType) {
      case 'tasks':
        final tasks = _localStorage.getAllTasks();
        if (since != null) {
          return tasks.where((task) {
            final updatedAt = DateTime.parse(task['updated_at']);
            return updatedAt.isAfter(since);
          }).toList();
        }
        return tasks;

      case 'subtasks':
        final allSubtasks = <Map<String, dynamic>>[];
        final tasks = _localStorage.getAllTasks();
        for (final task in tasks) {
          final subtasks = _localStorage.getSubtasksForTask(task['id']);
          allSubtasks.addAll(subtasks);
        }
        if (since != null) {
          return allSubtasks.where((subtask) {
            final updatedAt = DateTime.parse(subtask['updated_at']);
            return updatedAt.isAfter(since);
          }).toList();
        }
        return allSubtasks;

      case 'pomodoro_sessions':
        final sessions = _localStorage.getAllPomodoroSessions();
        if (since != null) {
          return sessions.where((session) {
            final updatedAt = DateTime.parse(session['updated_at']);
            return updatedAt.isAfter(since);
          }).toList();
        }
        return sessions;

      case 'notes':
        final allNotes = <Map<String, dynamic>>[];
        final tasks = _localStorage.getAllTasks();
        for (final task in tasks) {
          final notes = _localStorage.getNotesForTask(task['id']);
          allNotes.addAll(notes);
        }
        if (since != null) {
          return allNotes.where((note) {
            final updatedAt = DateTime.parse(note['updated_at']);
            return updatedAt.isAfter(since);
          }).toList();
        }
        return allNotes;

      case 'reminders':
        final allReminders = <Map<String, dynamic>>[];
        final tasks = _localStorage.getAllTasks();
        for (final task in tasks) {
          final reminders = _localStorage.getRemindersForTask(task['id']);
          allReminders.addAll(reminders);
        }
        if (since != null) {
          return allReminders.where((reminder) {
            final updatedAt = DateTime.parse(reminder['updated_at']);
            return updatedAt.isAfter(since);
          }).toList();
        }
        return allReminders;

      default:
        return [];
    }
  }

  Map<String, dynamic>? _getLocalItemById(String entityType, String itemId) {
    switch (entityType) {
      case 'tasks':
        return _localStorage.getTask(itemId);
      case 'subtasks':
        // Need to search through all subtasks
        final tasks = _localStorage.getAllTasks();
        for (final task in tasks) {
          final subtasks = _localStorage.getSubtasksForTask(task['id']);
          for (final subtask in subtasks) {
            if (subtask['id'] == itemId) {
              return subtask;
            }
          }
        }
        return null;
      default:
        return null;
    }
  }

  Future<void> _saveLocalItem(String entityType, Map<String, dynamic> item) async {
    switch (entityType) {
      case 'tasks':
        await _localStorage.saveTask(item['id'], item);
        break;
      case 'subtasks':
        await _localStorage.saveSubtask(item['id'], item);
        break;
      case 'pomodoro_sessions':
        await _localStorage.savePomodoroSession(item['id'], item);
        break;
      case 'notes':
        await _localStorage.saveNote(item['id'], item);
        break;
      case 'reminders':
        await _localStorage.saveReminder(item['id'], item);
        break;
    }
  }

  Future<void> _uploadLocalItem(String entityType, Map<String, dynamic> item) async {
    final endpoint = '/sync/$entityType';
    final response = await _apiClient.post(endpoint, data: item);

    if (!response.isSuccess) {
      throw Exception('Failed to upload ${entityType}: ${response.error}');
    }

    // Update local item with server response if needed
    if (response.data != null) {
      await _saveLocalItem(entityType, response.data);
    }
  }

  Future<ConflictResolution?> _resolveConflict(SyncConflict conflict) async {
    // Check for user-defined resolution for this specific conflict
    final existingResolution = _localStorage.getConflictResolution(conflict.entityId);
    if (existingResolution != null) {
      final resolutionStr = existingResolution['resolution'];
      return ConflictResolution.values.firstWhere(
        (e) => e.toString().split('.').last == resolutionStr,
        orElse: () => _defaultConflictResolution,
      );
    }

    // For automatic resolution, use the default strategy
    switch (_defaultConflictResolution) {
      case ConflictResolution.localWins:
        return ConflictResolution.localWins;
      case ConflictResolution.remoteWins:
        return ConflictResolution.remoteWins;
      case ConflictResolution.merge:
        return _attemptAutoMerge(conflict);
    }
  }

  ConflictResolution? _attemptAutoMerge(SyncConflict conflict) {
    // Simple merge strategy: prefer non-null values from either side
    final merged = Map<String, dynamic>.from(conflict.remoteData);

    for (final entry in conflict.localData.entries) {
      if (entry.value != null && merged[entry.key] == null) {
        merged[entry.key] = entry.value;
      }
    }

    // If merge is successful (no conflicting non-null values), use it
    // Otherwise, fall back to remote wins
    return ConflictResolution.remoteWins;
  }

  Future<void> _applyConflictResolution(String entityType, String itemId, ConflictResolution resolution) async {
    final conflict = _localStorage.getConflictResolution(itemId);
    if (conflict == null) return;

    Map<String, dynamic> resolvedData;

    switch (resolution) {
      case ConflictResolution.localWins:
        resolvedData = conflict['local_data'];
        // Upload local version to server
        await _uploadLocalItem(entityType, resolvedData);
        break;

      case ConflictResolution.remoteWins:
        resolvedData = conflict['remote_data'];
        // Save remote version locally
        await _saveLocalItem(entityType, resolvedData);
        break;

      case ConflictResolution.merge:
        resolvedData = _mergeConflictData(conflict['local_data'], conflict['remote_data']);
        // Save merged version locally and upload to server
        await _saveLocalItem(entityType, resolvedData);
        await _uploadLocalItem(entityType, resolvedData);
        break;
    }

    // Save resolution for reference
    await _localStorage.saveConflictResolution(itemId, resolution.toString().split('.').last, resolvedData);
  }

  Map<String, dynamic> _mergeConflictData(Map<String, dynamic> localData, Map<String, dynamic> remoteData) {
    final merged = Map<String, dynamic>.from(remoteData);

    // Prefer local changes for user-modifiable fields
    final userFields = ['title', 'description', 'priority', 'status', 'notes'];
    for (final field in userFields) {
      if (localData[field] != null && localData[field] != remoteData[field]) {
        merged[field] = localData[field];
      }
    }

    // Use latest timestamp
    final localUpdated = DateTime.parse(localData['updated_at']);
    final remoteUpdated = DateTime.parse(remoteData['updated_at']);
    merged['updated_at'] = localUpdated.isAfter(remoteUpdated) ? localData['updated_at'] : remoteData['updated_at'];

    return merged;
  }

  Future<void> _processOfflineQueue() async {
    final queue = _localStorage.getOfflineQueue();
    final pendingItems = queue.where((item) => item['status'] == 'pending').toList();

    for (final item in pendingItems) {
      try {
        await _localStorage.updateOfflineQueueItem(item['id'], {'status': 'processing'});

        final response = await _apiClient.request(
          item['method'],
          item['path'],
          data: item['data'],
          queryParameters: item['query_parameters'],
        );

        if (response.isSuccess) {
          await _localStorage.updateOfflineQueueItem(item['id'], {
            'status': 'completed',
            'completed_at': DateTime.now().toIso8601String(),
            'response': response.data,
          });
        } else {
          final retryCount = (item['retry_count'] ?? 0) + 1;
          if (retryCount >= 3) {
            await _localStorage.updateOfflineQueueItem(item['id'], {
              'status': 'failed',
              'retry_count': retryCount,
              'error': response.error,
            });
          } else {
            await _localStorage.updateOfflineQueueItem(item['id'], {
              'status': 'pending',
              'retry_count': retryCount,
              'last_error': response.error,
            });
          }
        }
      } catch (e) {
        final retryCount = (item['retry_count'] ?? 0) + 1;
        await _localStorage.updateOfflineQueueItem(item['id'], {
          'status': retryCount >= 3 ? 'failed' : 'pending',
          'retry_count': retryCount,
          'error': e.toString(),
        });
      }
    }
  }

  Future<void> resolveConflictManually(String entityId, ConflictResolution resolution, {Map<String, dynamic>? customData}) async {
    if (customData != null) {
      // Custom resolution with user-provided data
      final entityType = _getEntityTypeFromId(entityId);
      await _saveLocalItem(entityType, customData);
      await _uploadLocalItem(entityType, customData);
      await _localStorage.saveConflictResolution(entityId, 'custom', customData);
    } else {
      // Standard resolution
      final entityType = _getEntityTypeFromId(entityId);
      await _applyConflictResolution(entityType, entityId, resolution);
    }
  }

  String _getEntityTypeFromId(String entityId) {
    // This is a simplified approach - in a real app, you might need more sophisticated logic
    // to determine entity type from ID or store it with the conflict
    if (entityId.startsWith('task_')) return 'tasks';
    if (entityId.startsWith('subtask_')) return 'subtasks';
    if (entityId.startsWith('session_')) return 'pomodoro_sessions';
    if (entityId.startsWith('note_')) return 'notes';
    if (entityId.startsWith('reminder_')) return 'reminders';
    return 'tasks'; // Default fallback
  }

  Future<List<SyncConflict>> getPendingConflicts() async {
    final conflicts = <SyncConflict>[];
    // Implementation would load pending conflicts from storage
    return conflicts;
  }

  Future<Map<String, dynamic>> getSyncStats() async {
    final lastSyncTimes = <String, DateTime?>{};
    final entities = ['tasks', 'subtasks', 'pomodoro_sessions', 'notes', 'reminders', 'full_sync'];

    for (final entity in entities) {
      lastSyncTimes[entity] = _localStorage.getLastSyncTime(entity);
    }

    final offlineQueue = _localStorage.getOfflineQueue();
    final pendingCount = offlineQueue.where((item) => item['status'] == 'pending').length;
    final failedCount = offlineQueue.where((item) => item['status'] == 'failed').length;

    return {
      'last_sync_times': lastSyncTimes.map((k, v) => MapEntry(k, v?.toIso8601String())),
      'offline_queue_pending': pendingCount,
      'offline_queue_failed': failedCount,
      'auto_sync_enabled': _autoSyncEnabled,
      'sync_interval_minutes': _syncInterval.inMinutes,
      'default_conflict_resolution': _defaultConflictResolution.toString().split('.').last,
    };
  }

  Future<void> clearSyncData() async {
    await _localStorage.clearOfflineQueue();
    // Clear sync timestamps
    final entities = ['tasks', 'subtasks', 'pomodoro_sessions', 'notes', 'reminders', 'full_sync'];
    for (final entity in entities) {
      await _localStorage.saveLastSyncTime(entity, DateTime.fromMillisecondsSinceEpoch(0));
    }
  }

  void dispose() {
    _statusController.close();
    _resultController.close();
    _periodicSyncTimer?.cancel();
    _connectivitySubscription?.cancel();
  }
}