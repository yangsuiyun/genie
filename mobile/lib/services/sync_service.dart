import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../models/pomodoro_session.dart';
import '../api_service.dart';
import 'task_service.dart';
import 'session_service.dart';
import 'platform_storage.dart';

/// Service that manages synchronization between local storage and remote API
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  static const String _lastSyncKey = 'last_sync_time';

  final TaskService _taskService = TaskService();
  final SessionService _sessionService = SessionService();
  final PlatformStorage _storage = PlatformStorage();

  bool _isOnline = false;
  DateTime? _lastSyncTime;
  bool _syncInProgress = false;

  // Status getters
  bool get isOnline => _isOnline;
  DateTime? get lastSyncTime => _lastSyncTime;
  bool get isSyncInProgress => _syncInProgress;

  /// Initialize sync service
  Future<void> initialize() async {
    await _loadSyncState();
    await checkConnectivity();

    // Try to sync on startup if online
    if (_isOnline) {
      await syncAll();
    }
  }

  /// Check if server is online and update connectivity status
  Future<bool> checkConnectivity() async {
    try {
      _isOnline = await ApiService.isServerOnline();
      return _isOnline;
    } catch (e) {
      _isOnline = false;
      return false;
    }
  }

  /// Sync all data (tasks and sessions) with the server
  Future<SyncResult> syncAll() async {
    if (_syncInProgress) {
      return SyncResult(success: false, message: 'Sync already in progress');
    }

    _syncInProgress = true;

    try {
      // Check connectivity first
      if (!await checkConnectivity()) {
        return SyncResult(success: false, message: 'Server not available');
      }

      final taskResult = await syncTasks();
      final sessionResult = await syncSessions();

      final success = taskResult.success && sessionResult.success;
      final message = success
          ? 'Sync completed successfully'
          : 'Partial sync completed: ${taskResult.message}, ${sessionResult.message}';

      if (success) {
        _lastSyncTime = DateTime.now();
        await _saveSyncState();
      }

      return SyncResult(success: success, message: message);
    } finally {
      _syncInProgress = false;
    }
  }

  /// Sync tasks between local storage and server
  Future<SyncResult> syncTasks() async {
    try {
      // Get local tasks
      final localTasks = _taskService.tasks;

      // Get server tasks
      final serverTasks = await ApiService.getTasks();

      // Upload local tasks that don't exist on server
      final uploadResults = <bool>[];
      for (final localTask in localTasks) {
        final existsOnServer = serverTasks.any((t) => t.id == localTask.id);
        if (!existsOnServer) {
          final result = await ApiService.createTask(localTask);
          uploadResults.add(result != null);
        }
      }

      // Download server tasks that don't exist locally
      for (final serverTask in serverTasks) {
        final existsLocally = localTasks.any((t) => t.id == serverTask.id);
        if (!existsLocally) {
          await _taskService.addTask(serverTask);
        }
      }

      return SyncResult(
        success: true,
        message: 'Tasks synced: ${uploadResults.where((r) => r).length} uploaded, ${serverTasks.length} downloaded'
      );
    } catch (e) {
      return SyncResult(success: false, message: 'Task sync failed: $e');
    }
  }

  /// Sync sessions between local storage and server
  Future<SyncResult> syncSessions() async {
    try {
      // Get local sessions
      final localSessions = _sessionService.sessions;

      // Get server sessions
      final serverSessions = await ApiService.getSessions();

      // Upload local sessions that don't exist on server
      final uploadResults = <bool>[];
      for (final localSession in localSessions) {
        final existsOnServer = serverSessions.any((s) => s.id == localSession.id);
        if (!existsOnServer) {
          final result = await ApiService.startSession(localSession);
          if (result != null && localSession.status != SessionStatus.active) {
            // Update status if session is not active
            await ApiService.updateSession(localSession);
          }
          uploadResults.add(result != null);
        }
      }

      return SyncResult(
        success: true,
        message: 'Sessions synced: ${uploadResults.where((r) => r).length} uploaded, ${serverSessions.length} downloaded'
      );
    } catch (e) {
      return SyncResult(success: false, message: 'Session sync failed: $e');
    }
  }

  /// Get sync statistics
  Map<String, dynamic> getSyncStatistics() {
    return {
      'isOnline': _isOnline,
      'lastSyncTime': _lastSyncTime?.toIso8601String(),
      'syncInProgress': _syncInProgress,
      'localTasks': _taskService.tasks.length,
      'localSessions': _sessionService.sessions.length,
    };
  }

  /// Load sync state from storage
  Future<void> _loadSyncState() async {
    try {
      final lastSyncString = _storage.getItem(_lastSyncKey);
      if (lastSyncString != null) {
        _lastSyncTime = DateTime.parse(lastSyncString);
      }
    } catch (e) {
      print('Error loading sync state: $e');
    }
  }

  /// Save sync state to storage
  Future<void> _saveSyncState() async {
    try {
      if (_lastSyncTime != null) {
        _storage.setItem(_lastSyncKey, _lastSyncTime!.toIso8601String());
      }
    } catch (e) {
      print('Error saving sync state: $e');
    }
  }
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final String message;

  SyncResult({
    required this.success,
    required this.message,
  });

  @override
  String toString() => 'SyncResult(success: $success, message: $message)';
}

/// Sync status enumeration
enum SyncStatus {
  offline,
  online,
  syncing,
  synced,
  error;

  String get displayName {
    switch (this) {
      case SyncStatus.offline:
        return '离线';
      case SyncStatus.online:
        return '在线';
      case SyncStatus.syncing:
        return '同步中';
      case SyncStatus.synced:
        return '已同步';
      case SyncStatus.error:
        return '错误';
    }
  }
}