import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import '../services/local_storage.dart';
import '../services/notification_service.dart';

enum SessionType { work, shortBreak, longBreak }

enum SessionState { ready, running, paused, completed }

class PomodoroSession {
  final String id;
  final String? taskId;
  final SessionType type;
  final SessionState state;
  final Duration duration;
  final Duration remainingTime;
  final DateTime? startedAt;
  final DateTime? pausedAt;
  final DateTime? completedAt;
  final int rating;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  PomodoroSession({
    required this.id,
    this.taskId,
    required this.type,
    this.state = SessionState.ready,
    required this.duration,
    required this.remainingTime,
    this.startedAt,
    this.pausedAt,
    this.completedAt,
    this.rating = 0,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PomodoroSession.fromJson(Map<String, dynamic> json) => PomodoroSession(
        id: json['id'],
        taskId: json['task_id'],
        type: SessionType.values.firstWhere(
          (e) => e.toString().split('.').last == json['type'],
          orElse: () => SessionType.work,
        ),
        state: SessionState.values.firstWhere(
          (e) => e.toString().split('.').last == json['state'],
          orElse: () => SessionState.ready,
        ),
        duration: Duration(seconds: json['duration_seconds']),
        remainingTime: Duration(seconds: json['remaining_seconds']),
        startedAt: json['started_at'] != null ? DateTime.parse(json['started_at']) : null,
        pausedAt: json['paused_at'] != null ? DateTime.parse(json['paused_at']) : null,
        completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
        rating: json['rating'] ?? 0,
        notes: json['notes'],
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'task_id': taskId,
        'type': type.toString().split('.').last,
        'state': state.toString().split('.').last,
        'duration_seconds': duration.inSeconds,
        'remaining_seconds': remainingTime.inSeconds,
        'started_at': startedAt?.toIso8601String(),
        'paused_at': pausedAt?.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        'rating': rating,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  PomodoroSession copyWith({
    String? id,
    String? taskId,
    SessionType? type,
    SessionState? state,
    Duration? duration,
    Duration? remainingTime,
    DateTime? startedAt,
    DateTime? pausedAt,
    DateTime? completedAt,
    int? rating,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      PomodoroSession(
        id: id ?? this.id,
        taskId: taskId ?? this.taskId,
        type: type ?? this.type,
        state: state ?? this.state,
        duration: duration ?? this.duration,
        remainingTime: remainingTime ?? this.remainingTime,
        startedAt: startedAt ?? this.startedAt,
        pausedAt: pausedAt ?? this.pausedAt,
        completedAt: completedAt ?? this.completedAt,
        rating: rating ?? this.rating,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  double get progress => state == SessionState.ready
      ? 0.0
      : (duration.inSeconds - remainingTime.inSeconds) / duration.inSeconds;

  bool get isActive => state == SessionState.running;
  bool get isPaused => state == SessionState.paused;
  bool get isCompleted => state == SessionState.completed;
  bool get canStart => state == SessionState.ready || state == SessionState.paused;
  bool get canPause => state == SessionState.running;
  bool get canStop => state == SessionState.running || state == SessionState.paused;
}

class PomodoroSettings {
  final Duration workDuration;
  final Duration shortBreakDuration;
  final Duration longBreakDuration;
  final int longBreakInterval;
  final bool autoStartBreaks;
  final bool autoStartPomodoros;
  final String workEndSound;
  final String breakEndSound;
  final double volume;
  final bool enableNotifications;
  final bool enableTickingSound;

  PomodoroSettings({
    this.workDuration = const Duration(minutes: 25),
    this.shortBreakDuration = const Duration(minutes: 5),
    this.longBreakDuration = const Duration(minutes: 15),
    this.longBreakInterval = 4,
    this.autoStartBreaks = false,
    this.autoStartPomodoros = false,
    this.workEndSound = 'bell',
    this.breakEndSound = 'chime',
    this.volume = 0.8,
    this.enableNotifications = true,
    this.enableTickingSound = false,
  });

  factory PomodoroSettings.fromJson(Map<String, dynamic> json) => PomodoroSettings(
        workDuration: Duration(minutes: json['work_duration_minutes'] ?? 25),
        shortBreakDuration: Duration(minutes: json['short_break_duration_minutes'] ?? 5),
        longBreakDuration: Duration(minutes: json['long_break_duration_minutes'] ?? 15),
        longBreakInterval: json['long_break_interval'] ?? 4,
        autoStartBreaks: json['auto_start_breaks'] ?? false,
        autoStartPomodoros: json['auto_start_pomodoros'] ?? false,
        workEndSound: json['work_end_sound'] ?? 'bell',
        breakEndSound: json['break_end_sound'] ?? 'chime',
        volume: (json['volume'] ?? 0.8).toDouble(),
        enableNotifications: json['enable_notifications'] ?? true,
        enableTickingSound: json['enable_ticking_sound'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'work_duration_minutes': workDuration.inMinutes,
        'short_break_duration_minutes': shortBreakDuration.inMinutes,
        'long_break_duration_minutes': longBreakDuration.inMinutes,
        'long_break_interval': longBreakInterval,
        'auto_start_breaks': autoStartBreaks,
        'auto_start_pomodoros': autoStartPomodoros,
        'work_end_sound': workEndSound,
        'break_end_sound': breakEndSound,
        'volume': volume,
        'enable_notifications': enableNotifications,
        'enable_ticking_sound': enableTickingSound,
      };

  PomodoroSettings copyWith({
    Duration? workDuration,
    Duration? shortBreakDuration,
    Duration? longBreakDuration,
    int? longBreakInterval,
    bool? autoStartBreaks,
    bool? autoStartPomodoros,
    String? workEndSound,
    String? breakEndSound,
    double? volume,
    bool? enableNotifications,
    bool? enableTickingSound,
  }) =>
      PomodoroSettings(
        workDuration: workDuration ?? this.workDuration,
        shortBreakDuration: shortBreakDuration ?? this.shortBreakDuration,
        longBreakDuration: longBreakDuration ?? this.longBreakDuration,
        longBreakInterval: longBreakInterval ?? this.longBreakInterval,
        autoStartBreaks: autoStartBreaks ?? this.autoStartBreaks,
        autoStartPomodoros: autoStartPomodoros ?? this.autoStartPomodoros,
        workEndSound: workEndSound ?? this.workEndSound,
        breakEndSound: breakEndSound ?? this.breakEndSound,
        volume: volume ?? this.volume,
        enableNotifications: enableNotifications ?? this.enableNotifications,
        enableTickingSound: enableTickingSound ?? this.enableTickingSound,
      );
}

class PomodoroNotifier extends StateNotifier<PomodoroSession?> {
  PomodoroNotifier() : super(null) {
    _initialize();
  }

  final ApiClient _apiClient = ApiClient.instance;
  final LocalStorage _localStorage = LocalStorage.instance;
  final NotificationService _notificationService = NotificationService.instance;

  Timer? _timer;
  int _completedPomodoros = 0;

  Future<void> _initialize() async {
    await _localStorage.initialize();
    await _notificationService.initialize();

    // Load any active session from storage
    await _loadActiveSession();
  }

  Future<void> _loadActiveSession() async {
    final sessions = _localStorage.getAllPomodoroSessions();
    final activeSession = sessions
        .where((session) => session['state'] == 'running' || session['state'] == 'paused')
        .map((sessionData) => PomodoroSession.fromJson(sessionData))
        .firstOrNull;

    if (activeSession != null) {
      state = activeSession;

      // If the session was running, we need to calculate the actual remaining time
      if (activeSession.state == SessionState.running && activeSession.startedAt != null) {
        final elapsed = DateTime.now().difference(activeSession.startedAt!);
        final newRemainingTime = activeSession.duration - elapsed;

        if (newRemainingTime.isNegative) {
          // Session should have completed while app was closed
          await _completeSession();
        } else {
          // Update remaining time and resume timer
          state = activeSession.copyWith(remainingTime: newRemainingTime);
          _startTimer();
        }
      }
    }
  }

  Future<PomodoroSession?> createSession({
    String? taskId,
    SessionType? type,
    Duration? customDuration,
  }) async {
    final settings = await _getSettings();
    final sessionType = type ?? _getNextSessionType();

    Duration duration;
    switch (sessionType) {
      case SessionType.work:
        duration = customDuration ?? settings.workDuration;
        break;
      case SessionType.shortBreak:
        duration = customDuration ?? settings.shortBreakDuration;
        break;
      case SessionType.longBreak:
        duration = customDuration ?? settings.longBreakDuration;
        break;
    }

    try {
      final response = await _apiClient.post('/pomodoro/sessions', data: {
        'task_id': taskId,
        'type': sessionType.toString().split('.').last,
        'duration_seconds': duration.inSeconds,
      });

      if (response.isSuccess) {
        final session = PomodoroSession.fromJson(response.data);

        // Save to local storage
        await _localStorage.savePomodoroSession(session.id, session.toJson());

        state = session;
        return session;
      } else {
        throw Exception(response.error ?? 'Failed to create session');
      }
    } catch (e) {
      rethrow;
    }
  }

  SessionType _getNextSessionType() {
    if (_completedPomodoros == 0) return SessionType.work;

    final settings = PomodoroSettings.fromJson(
      _localStorage.getAllSettings(),
    );

    if (_completedPomodoros % settings.longBreakInterval == 0) {
      return SessionType.longBreak;
    } else {
      return SessionType.shortBreak;
    }
  }

  Future<void> startSession() async {
    final session = state;
    if (session == null || !session.canStart) return;

    try {
      final response = await _apiClient.put('/pomodoro/sessions/${session.id}', data: {
        'state': 'running',
        'started_at': DateTime.now().toIso8601String(),
      });

      if (response.isSuccess) {
        final updatedSession = PomodoroSession.fromJson(response.data);

        // Save to local storage
        await _localStorage.savePomodoroSession(updatedSession.id, updatedSession.toJson());

        state = updatedSession;
        _startTimer();

        // Schedule notification
        final taskTitle = await _getTaskTitle(session.taskId);
        await _notificationService.schedulePomodoroNotification(
          sessionId: session.id,
          taskTitle: taskTitle ?? 'Untitled Task',
          sessionDuration: session.remainingTime,
          isBreak: session.type != SessionType.work,
        );
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> pauseSession() async {
    final session = state;
    if (session == null || !session.canPause) return;

    _stopTimer();

    try {
      final response = await _apiClient.put('/pomodoro/sessions/${session.id}', data: {
        'state': 'paused',
        'paused_at': DateTime.now().toIso8601String(),
        'remaining_seconds': session.remainingTime.inSeconds,
      });

      if (response.isSuccess) {
        final updatedSession = PomodoroSession.fromJson(response.data);

        // Save to local storage
        await _localStorage.savePomodoroSession(updatedSession.id, updatedSession.toJson());

        state = updatedSession;

        // Cancel notification
        await _notificationService.cancelPomodoroNotification(session.id);
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> stopSession() async {
    final session = state;
    if (session == null || !session.canStop) return;

    _stopTimer();

    try {
      final response = await _apiClient.put('/pomodoro/sessions/${session.id}', data: {
        'state': 'ready',
        'remaining_seconds': session.duration.inSeconds,
      });

      if (response.isSuccess) {
        final updatedSession = PomodoroSession.fromJson(response.data);

        // Save to local storage
        await _localStorage.savePomodoroSession(updatedSession.id, updatedSession.toJson());

        state = updatedSession;

        // Cancel notification
        await _notificationService.cancelPomodoroNotification(session.id);
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _completeSession() async {
    final session = state;
    if (session == null) return;

    _stopTimer();

    try {
      final response = await _apiClient.put('/pomodoro/sessions/${session.id}', data: {
        'state': 'completed',
        'completed_at': DateTime.now().toIso8601String(),
        'remaining_seconds': 0,
      });

      if (response.isSuccess) {
        final completedSession = PomodoroSession.fromJson(response.data);

        // Save to local storage
        await _localStorage.savePomodoroSession(completedSession.id, completedSession.toJson());

        state = completedSession;

        // Update completed pomodoros count
        if (session.type == SessionType.work) {
          _completedPomodoros++;
        }

        // Play completion sound and show notification
        await _handleSessionCompletion(completedSession);

        // Auto-start next session if enabled
        await _handleAutoStart(completedSession);
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _handleSessionCompletion(PomodoroSession session) async {
    final settings = await _getSettings();

    // Play sound
    // Implementation would play audio using audioplayers package

    // Show local notification if app is in background
    final taskTitle = await _getTaskTitle(session.taskId);
    await _notificationService.schedulePomodoroNotification(
      sessionId: session.id,
      taskTitle: taskTitle ?? 'Untitled Task',
      sessionDuration: Duration.zero,
      isBreak: session.type != SessionType.work,
    );
  }

  Future<void> _handleAutoStart(PomodoroSession completedSession) async {
    final settings = await _getSettings();

    bool shouldAutoStart = false;
    if (completedSession.type == SessionType.work && settings.autoStartBreaks) {
      shouldAutoStart = true;
    } else if (completedSession.type != SessionType.work && settings.autoStartPomodoros) {
      shouldAutoStart = true;
    }

    if (shouldAutoStart) {
      // Wait a moment before auto-starting
      await Future.delayed(const Duration(seconds: 3));

      final nextSession = await createSession(
        taskId: completedSession.taskId,
        type: _getNextSessionType(),
      );

      if (nextSession != null) {
        await startSession();
      }
    }
  }

  void _startTimer() {
    _stopTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final session = state;
      if (session == null || session.remainingTime.inSeconds <= 0) {
        _completeSession();
        return;
      }

      final newRemainingTime = session.remainingTime - const Duration(seconds: 1);
      state = session.copyWith(remainingTime: newRemainingTime);

      // Update local storage every 10 seconds
      if (newRemainingTime.inSeconds % 10 == 0) {
        _localStorage.savePomodoroSession(session.id, state!.toJson());
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> rateSession(int rating, {String? notes}) async {
    final session = state;
    if (session == null || !session.isCompleted) return;

    try {
      final response = await _apiClient.put('/pomodoro/sessions/${session.id}', data: {
        'rating': rating,
        'notes': notes,
      });

      if (response.isSuccess) {
        final updatedSession = PomodoroSession.fromJson(response.data);

        // Save to local storage
        await _localStorage.savePomodoroSession(updatedSession.id, updatedSession.toJson());

        state = updatedSession;
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> skipSession() async {
    final session = state;
    if (session == null) return;

    await _completeSession();
  }

  Future<void> addTime(Duration duration) async {
    final session = state;
    if (session == null) return;

    final newRemainingTime = session.remainingTime + duration;
    final newDuration = session.duration + duration;

    state = session.copyWith(
      remainingTime: newRemainingTime,
      duration: newDuration,
    );

    // Update on server
    try {
      await _apiClient.put('/pomodoro/sessions/${session.id}', data: {
        'duration_seconds': newDuration.inSeconds,
        'remaining_seconds': newRemainingTime.inSeconds,
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<PomodoroSettings> _getSettings() async {
    final settingsData = _localStorage.getAllSettings();
    return PomodoroSettings.fromJson(settingsData);
  }

  Future<String?> _getTaskTitle(String? taskId) async {
    if (taskId == null) return null;

    final taskData = _localStorage.getTask(taskId);
    return taskData?['title'];
  }

  void clearSession() {
    _stopTimer();
    state = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}

class PomodoroSettingsNotifier extends StateNotifier<PomodoroSettings> {
  PomodoroSettingsNotifier() : super(PomodoroSettings()) {
    _initialize();
  }

  final LocalStorage _localStorage = LocalStorage.instance;

  Future<void> _initialize() async {
    await _localStorage.initialize();

    final settingsData = _localStorage.getAllSettings();
    state = PomodoroSettings.fromJson(settingsData);
  }

  Future<void> updateSettings({
    Duration? workDuration,
    Duration? shortBreakDuration,
    Duration? longBreakDuration,
    int? longBreakInterval,
    bool? autoStartBreaks,
    bool? autoStartPomodoros,
    String? workEndSound,
    String? breakEndSound,
    double? volume,
    bool? enableNotifications,
    bool? enableTickingSound,
  }) async {
    final newSettings = state.copyWith(
      workDuration: workDuration,
      shortBreakDuration: shortBreakDuration,
      longBreakDuration: longBreakDuration,
      longBreakInterval: longBreakInterval,
      autoStartBreaks: autoStartBreaks,
      autoStartPomodoros: autoStartPomodoros,
      workEndSound: workEndSound,
      breakEndSound: breakEndSound,
      volume: volume,
      enableNotifications: enableNotifications,
      enableTickingSound: enableTickingSound,
    );

    await _localStorage.saveSettings(newSettings.toJson());
    state = newSettings;
  }

  Future<void> resetToDefaults() async {
    final defaultSettings = PomodoroSettings();
    await _localStorage.saveSettings(defaultSettings.toJson());
    state = defaultSettings;
  }
}

class PomodoroHistoryNotifier extends StateNotifier<AsyncValue<List<PomodoroSession>>> {
  PomodoroHistoryNotifier() : super(const AsyncValue.loading()) {
    _initialize();
  }

  final ApiClient _apiClient = ApiClient.instance;
  final LocalStorage _localStorage = LocalStorage.instance;

  Future<void> _initialize() async {
    await _localStorage.initialize();
    await loadHistory();
  }

  Future<void> loadHistory({
    DateTime? startDate,
    DateTime? endDate,
    String? taskId,
    SessionType? type,
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh) {
        // Load from local storage first
        final localSessions = _localStorage.getAllPomodoroSessions()
            .map((sessionData) => PomodoroSession.fromJson(sessionData))
            .toList();

        if (localSessions.isNotEmpty) {
          final filteredSessions = _applyFilters(localSessions, startDate, endDate, taskId, type);
          state = AsyncValue.data(filteredSessions);
        }
      }

      // Fetch from server
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
      if (taskId != null) queryParams['task_id'] = taskId;
      if (type != null) queryParams['type'] = type.toString().split('.').last;

      final response = await _apiClient.get('/pomodoro/sessions', queryParameters: queryParams);

      if (response.isSuccess) {
        final sessions = (response.data['sessions'] as List)
            .map((sessionData) => PomodoroSession.fromJson(sessionData))
            .toList();

        // Save to local storage
        for (final session in sessions) {
          await _localStorage.savePomodoroSession(session.id, session.toJson());
        }

        state = AsyncValue.data(sessions);
      } else {
        throw Exception(response.error ?? 'Failed to load history');
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  List<PomodoroSession> _applyFilters(
    List<PomodoroSession> sessions,
    DateTime? startDate,
    DateTime? endDate,
    String? taskId,
    SessionType? type,
  ) {
    return sessions.where((session) {
      if (startDate != null && session.createdAt.isBefore(startDate)) return false;
      if (endDate != null && session.createdAt.isAfter(endDate)) return false;
      if (taskId != null && session.taskId != taskId) return false;
      if (type != null && session.type != type) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}

// Provider definitions
final pomodoroProvider = StateNotifierProvider<PomodoroNotifier, PomodoroSession?>((ref) {
  return PomodoroNotifier();
});

final pomodoroSettingsProvider = StateNotifierProvider<PomodoroSettingsNotifier, PomodoroSettings>((ref) {
  return PomodoroSettingsNotifier();
});

final pomodoroHistoryProvider = StateNotifierProvider<PomodoroHistoryNotifier, AsyncValue<List<PomodoroSession>>>((ref) {
  return PomodoroHistoryNotifier();
});

final currentSessionProvider = Provider<PomodoroSession?>((ref) {
  return ref.watch(pomodoroProvider);
});

final sessionStateProvider = Provider<SessionState?>((ref) {
  return ref.watch(pomodoroProvider)?.state;
});

final isSessionActiveProvider = Provider<bool>((ref) {
  return ref.watch(pomodoroProvider)?.isActive ?? false;
});

final sessionProgressProvider = Provider<double>((ref) {
  return ref.watch(pomodoroProvider)?.progress ?? 0.0;
});

final remainingTimeProvider = Provider<Duration>((ref) {
  return ref.watch(pomodoroProvider)?.remainingTime ?? Duration.zero;
});

final completedSessionsTodayProvider = Provider<int>((ref) {
  final sessions = ref.watch(pomodoroHistoryProvider).value ?? [];
  final today = DateTime.now();

  return sessions
      .where((session) =>
          session.isCompleted &&
          session.type == SessionType.work &&
          session.completedAt != null &&
          session.completedAt!.year == today.year &&
          session.completedAt!.month == today.month &&
          session.completedAt!.day == today.day)
      .length;
});

final sessionStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final sessions = ref.watch(pomodoroHistoryProvider).value ?? [];
  final completedSessions = sessions.where((s) => s.isCompleted).toList();

  final workSessions = completedSessions.where((s) => s.type == SessionType.work).length;
  final breakSessions = completedSessions.where((s) => s.type != SessionType.work).length;

  final totalFocusTime = completedSessions
      .where((s) => s.type == SessionType.work)
      .fold<Duration>(Duration.zero, (sum, session) => sum + session.duration);

  final averageRating = completedSessions.isNotEmpty
      ? completedSessions.map((s) => s.rating).reduce((a, b) => a + b) / completedSessions.length
      : 0.0;

  return {
    'total_sessions': completedSessions.length,
    'work_sessions': workSessions,
    'break_sessions': breakSessions,
    'total_focus_time': totalFocusTime,
    'average_rating': averageRating,
  };
});