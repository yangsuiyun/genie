import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/index.dart';
import 'platform_storage.dart';

class SessionService {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  static const String _storageKey = 'pomodoro_sessions';
  List<PomodoroSession> _sessions = [];
  final List<VoidCallback> _listeners = [];
  final PlatformStorage _storage = PlatformStorage();

  // 获取所有会话
  List<PomodoroSession> get sessions => List.unmodifiable(_sessions);

  // 获取所有会话（方法形式）
  List<PomodoroSession> getSessions() => List.unmodifiable(_sessions);

  // 添加监听器
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  // 移除监听器
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  // 通知监听器
  void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }

  // 初始化
  Future<void> initialize() async {
    await _loadFromStorage();
  }

  // 开始新会话
  Future<PomodoroSession> startSession({
    Task? task,
    required int plannedDuration,
    SessionType type = SessionType.work,
  }) async {
    final session = PomodoroSession.create(
      taskId: task?.id,
      taskTitle: task?.title,
      plannedDuration: plannedDuration,
      type: type,
    );

    _sessions.add(session);
    await _saveToStorage();
    _notifyListeners();
    return session;
  }

  // 完成会话
  Future<PomodoroSession> completeSession(
    String sessionId, {
    int? actualDuration,
    String? notes,
  }) async {
    final sessionIndex = _sessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex == -1) {
      throw Exception('Session not found');
    }

    final session = _sessions[sessionIndex];
    final completedSession = session.copyWith(
      endTime: DateTime.now(),
      actualDuration: actualDuration ?? session.plannedDuration,
      status: SessionStatus.completed,
      notes: notes,
    );

    _sessions[sessionIndex] = completedSession;
    await _saveToStorage();
    _notifyListeners();
    return completedSession;
  }

  // 中断会话
  Future<PomodoroSession> interruptSession(
    String sessionId, {
    int? actualDuration,
    String? notes,
  }) async {
    final sessionIndex = _sessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex == -1) {
      throw Exception('Session not found');
    }

    final session = _sessions[sessionIndex];
    final interruptedSession = session.copyWith(
      endTime: DateTime.now(),
      actualDuration: actualDuration ?? 0,
      status: SessionStatus.interrupted,
      notes: notes,
    );

    _sessions[sessionIndex] = interruptedSession;
    await _saveToStorage();
    _notifyListeners();
    return interruptedSession;
  }

  // 暂停会话
  Future<PomodoroSession> pauseSession(String sessionId) async {
    final sessionIndex = _sessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex == -1) {
      throw Exception('Session not found');
    }

    final session = _sessions[sessionIndex];
    final pausedSession = session.copyWith(status: SessionStatus.paused);

    _sessions[sessionIndex] = pausedSession;
    await _saveToStorage();
    _notifyListeners();
    return pausedSession;
  }

  // 恢复会话
  Future<PomodoroSession> resumeSession(String sessionId) async {
    final sessionIndex = _sessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex == -1) {
      throw Exception('Session not found');
    }

    final session = _sessions[sessionIndex];
    final resumedSession = session.copyWith(status: SessionStatus.active);

    _sessions[sessionIndex] = resumedSession;
    await _saveToStorage();
    _notifyListeners();
    return resumedSession;
  }

  // 获取任务的会话历史
  List<PomodoroSession> getSessionsForTask(String taskId) {
    return _sessions.where((session) => session.taskId == taskId).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  // 获取今日会话
  List<PomodoroSession> getTodaySessions() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _sessions.where((session) {
      return session.startTime.isAfter(startOfDay) &&
          session.startTime.isBefore(endOfDay);
    }).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  // 获取本周会话
  List<PomodoroSession> getThisWeekSessions() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    return _sessions.where((session) {
      return session.startTime.isAfter(startOfWeekDate);
    }).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  // 获取指定日期范围的会话
  List<PomodoroSession> getSessionsInRange(DateTime start, DateTime end) {
    return _sessions.where((session) {
      return session.startTime.isAfter(start) && session.startTime.isBefore(end);
    }).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  // 获取会话统计
  SessionStatistics getStatistics() {
    final totalSessions = _sessions.length;
    final completedSessions = _sessions.where((s) => s.isCompleted).length;
    final interruptedSessions = _sessions.where((s) => s.isInterrupted).length;

    // 计算总专注时间（只计算完成的工作会话）
    final completedWorkSessions = _sessions.where(
      (s) => s.isCompleted && s.type == SessionType.work,
    );

    Duration totalFocusTime = Duration.zero;
    for (var session in completedWorkSessions) {
      totalFocusTime += Duration(seconds: session.actualDuration);
    }

    // 计算平均会话时间
    Duration averageSessionTime = Duration.zero;
    if (completedSessions > 0) {
      final totalCompletedDuration = _sessions
          .where((s) => s.isCompleted)
          .fold<int>(0, (sum, session) => sum + session.actualDuration);
      averageSessionTime = Duration(seconds: totalCompletedDuration ~/ completedSessions);
    }

    // 计算完成率
    final completionRate = totalSessions > 0 ? completedSessions / totalSessions : 0.0;

    // 今日统计
    final todaySessions = getTodaySessions();
    final todayCompletedWork = todaySessions.where(
      (s) => s.isCompleted && s.type == SessionType.work,
    );

    Duration todayFocusTime = Duration.zero;
    for (var session in todayCompletedWork) {
      todayFocusTime += Duration(seconds: session.actualDuration);
    }

    return SessionStatistics(
      totalSessions: totalSessions,
      completedSessions: completedSessions,
      interruptedSessions: interruptedSessions,
      totalFocusTime: totalFocusTime,
      averageSessionTime: averageSessionTime,
      completionRate: completionRate,
      todaySessions: todaySessions.length,
      todayFocusTime: todayFocusTime,
    );
  }

  // 获取每日专注时间统计（最近7天）
  Map<DateTime, Duration> getDailyFocusTime({int days = 7}) {
    final now = DateTime.now();
    final result = <DateTime, Duration>{};

    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final daySessions = _sessions.where((session) {
        return session.startTime.isAfter(dayStart) &&
            session.startTime.isBefore(dayEnd) &&
            session.isCompleted &&
            session.type == SessionType.work;
      });

      Duration dayFocusTime = Duration.zero;
      for (var session in daySessions) {
        dayFocusTime += Duration(seconds: session.actualDuration);
      }

      result[dayStart] = dayFocusTime;
    }

    return result;
  }

  // 获取任务专注时间统计
  Map<String, Duration> getTaskFocusTime() {
    final result = <String, Duration>{};

    for (var session in _sessions) {
      if (session.isCompleted &&
          session.type == SessionType.work &&
          session.taskTitle != null) {
        final taskTitle = session.taskTitle!;
        final duration = Duration(seconds: session.actualDuration);
        result[taskTitle] = (result[taskTitle] ?? Duration.zero) + duration;
      }
    }

    return result;
  }

  // 获取周趋势数据（最近7天的每日番茄钟数量）
  Map<int, int> getWeeklyTrend() {
    final now = DateTime.now();
    final result = <int, int>{};

    // 初始化7天数据
    for (int i = 0; i < 7; i++) {
      result[i] = 0;
    }

    for (var session in _sessions) {
      if (session.isCompleted && session.type == SessionType.work) {
        final sessionDate = session.startTime;
        final daysDifference = now.difference(sessionDate).inDays;

        if (daysDifference >= 0 && daysDifference < 7) {
          final dayIndex = (6 - daysDifference) % 7; // 0=今天往前6天, 6=今天
          result[dayIndex] = (result[dayIndex] ?? 0) + 1;
        }
      }
    }

    return result;
  }

  // 获取每小时分布数据
  Map<int, int> getHourlyDistribution() {
    final result = <int, int>{};

    // 初始化24小时数据
    for (int i = 0; i < 24; i++) {
      result[i] = 0;
    }

    for (var session in _sessions) {
      if (session.isCompleted && session.type == SessionType.work) {
        final hour = session.startTime.hour;
        result[hour] = (result[hour] ?? 0) + 1;
      }
    }

    return result;
  }

  // 删除会话
  Future<void> deleteSession(String sessionId) async {
    _sessions.removeWhere((session) => session.id == sessionId);
    await _saveToStorage();
    _notifyListeners();
  }

  // 清除所有会话数据
  Future<void> clearAllSessions() async {
    _sessions.clear();
    _storage.removeItem(_storageKey);
    _notifyListeners();
  }

  // 从本地存储加载
  Future<void> _loadFromStorage() async {
    try {
      final sessionsJson = _storage.getItem(_storageKey);

      if (sessionsJson != null && sessionsJson.isNotEmpty) {
        final List<dynamic> sessionsList = json.decode(sessionsJson);
        _sessions = sessionsList
            .map((sessionJson) => PomodoroSession.fromJson(sessionJson))
            .toList();
      }
    } catch (e) {
      print('Error loading sessions from storage: $e');
      _sessions = [];
    }
  }

  // 保存到本地存储
  Future<void> _saveToStorage() async {
    try {
      final sessionsJson = json.encode(
          _sessions.map((session) => session.toJson()).toList());
      _storage.setItem(_storageKey, sessionsJson);
    } catch (e) {
      print('Error saving sessions to storage: $e');
    }
  }

  // 导入单个会话 (用于兼容性)
  Future<void> importSession(PomodoroSession session) async {
    _sessions.add(session);
    await _saveToStorage();
    _notifyListeners();
  }

  // 导出会话数据
  String exportData() {
    return json.encode({
      'sessions': _sessions.map((session) => session.toJson()).toList(),
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0',
    });
  }

  // 导入会话数据
  Future<bool> importData(String jsonData) async {
    try {
      final data = json.decode(jsonData);
      final List<dynamic> sessionsList = data['sessions'];
      _sessions = sessionsList
          .map((sessionJson) => PomodoroSession.fromJson(sessionJson))
          .toList();
      await _saveToStorage();
      _notifyListeners();
      return true;
    } catch (e) {
      print('Error importing session data: $e');
      return false;
    }
  }

  // 获取最近的活动会话
  PomodoroSession? getActiveSession() {
    try {
      return _sessions.firstWhere((session) => session.isActive);
    } catch (e) {
      return null;
    }
  }

  // 获取生产力洞察
  Map<String, dynamic> getProductivityInsights() {
    final stats = getStatistics();
    final dailyStats = getDailyFocusTime();
    final taskStats = getTaskFocusTime();

    // 计算最佳工作时间段
    final hourlyStats = <int, int>{};
    for (var session in _sessions) {
      if (session.isCompleted && session.type == SessionType.work) {
        final hour = session.startTime.hour;
        hourlyStats[hour] = (hourlyStats[hour] ?? 0) + 1;
      }
    }

    int? bestHour;
    int maxSessions = 0;
    hourlyStats.forEach((hour, count) {
      if (count > maxSessions) {
        maxSessions = count;
        bestHour = hour;
      }
    });

    // 计算连续专注天数
    int streakDays = 0;
    final now = DateTime.now();
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final hasWorkSession = _sessions.any((session) =>
          session.startTime.isAfter(dayStart) &&
          session.startTime.isBefore(dayEnd) &&
          session.isCompleted &&
          session.type == SessionType.work);

      if (hasWorkSession) {
        streakDays++;
      } else {
        break;
      }
    }

    return {
      'totalFocusTime': stats.totalFocusTime,
      'todayFocusTime': stats.todayFocusTime,
      'completionRate': stats.completionRate,
      'streakDays': streakDays,
      'bestWorkingHour': bestHour,
      'topTasks': taskStats.entries
          .toList()
          ..sort((a, b) => b.value.compareTo(a.value)),
      'weeklyTrend': dailyStats,
    };
  }
}