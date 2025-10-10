import 'dart:async';
import 'package:flutter/material.dart';
import '../models/index.dart';

// 完整的PomodoroState管理类
class PomodoroState {
  static final PomodoroState _instance = PomodoroState._internal();
  factory PomodoroState() => _instance;
  PomodoroState._internal();

  Timer? _timer;
  bool _isRunning = false;
  int _remainingSeconds = 25 * 60; // 25分钟 = 1500秒
  int _totalSeconds = 25 * 60;
  Task? _currentTask;
  PomodoroSession? _currentSession;

  // 番茄钟循环管理
  int _completedPomodoros = 0;
  bool _isBreakTime = false;
  SessionType _currentSessionType = SessionType.work;
  int _longBreakInterval = 4; // 每4个番茄钟后长休息

  // 状态变化监听器
  final List<VoidCallback> _listeners = [];

  // Getters
  bool get isRunning => _isRunning;
  int get remainingSeconds => _remainingSeconds;
  int get totalSeconds => _totalSeconds;
  double get progress => 1.0 - (_remainingSeconds / _totalSeconds);
  Task? get currentTask => _currentTask;
  PomodoroSession? get currentSession => _currentSession;
  int get completedPomodoros => _completedPomodoros;
  bool get isBreakTime => _isBreakTime;
  SessionType get currentSessionType => _currentSessionType;

  String get timeDisplay {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get statusText {
    if (_isBreakTime) {
      return _currentSessionType == SessionType.longBreak ? '长休息时间' : '短休息时间';
    }
    return _currentTask != null ? '专注处理: ${_currentTask!.title}' : '自由番茄钟专注中';
  }

  Color get progressColor {
    if (_isBreakTime) {
      return _currentSessionType == SessionType.longBreak ? Colors.blue : Colors.green;
    }
    return Colors.red;
  }

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }

  void start([Task? task, SessionType? sessionType]) async {
    if (_isRunning) return;

    _currentTask = task;
    
    // 确定会话类型
    if (sessionType != null) {
      _currentSessionType = sessionType;
    } else if (!_isBreakTime) {
      _currentSessionType = SessionType.work;
    }

    // 设置时间
    _setSessionDuration();

    // 创建会话
    _currentSession = PomodoroSession.create(
      taskId: task?.id,
      type: _currentSessionType,
      plannedDuration: _totalSeconds,
    );

    _isRunning = true;
    _startTimer();
    _notifyListeners();
  }

  void pause() {
    _isRunning = false;
    _timer?.cancel();
    _notifyListeners();
  }

  void resume() {
    if (_currentSession == null) return;
    _isRunning = true;
    _startTimer();
    _notifyListeners();
  }

  void reset() {
    _isRunning = false;
    _timer?.cancel();
    _setSessionDuration();
    _notifyListeners();
  }

  void skip() {
    _timer?.cancel();
    _remainingSeconds = 0;
    _onSessionComplete();
  }

  void _setSessionDuration() {
    switch (_currentSessionType) {
      case SessionType.work:
        _totalSeconds = 25 * 60; // 25分钟
        break;
      case SessionType.shortBreak:
        _totalSeconds = 5 * 60; // 5分钟
        break;
      case SessionType.longBreak:
        _totalSeconds = 15 * 60; // 15分钟
        break;
    }
    _remainingSeconds = _totalSeconds;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        _notifyListeners();
      } else {
        _onSessionComplete();
      }
    });
  }

  void _onSessionComplete() {
    _timer?.cancel();
    _isRunning = false;

    // 完成当前会话
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(
        endTime: DateTime.now(),
        status: SessionStatus.completed,
        actualDuration: _totalSeconds - _remainingSeconds,
      );
    }

    // 更新任务进度
    if (_currentTask != null && _currentSessionType == SessionType.work) {
      _completedPomodoros++;
      _currentTask = _currentTask!.copyWith(
        completedPomodoros: _completedPomodoros,
      );
    }

    // 决定下一个会话类型
    _determineNextSession();

    _notifyListeners();

    // 显示完成通知
    _showCompletionNotification();
  }

  void _determineNextSession() {
    if (_currentSessionType == SessionType.work) {
      // 工作完成后，决定休息类型
      if (_completedPomodoros % _longBreakInterval == 0) {
        _currentSessionType = SessionType.longBreak;
      } else {
        _currentSessionType = SessionType.shortBreak;
      }
      _isBreakTime = true;
    } else {
      // 休息完成后，回到工作
      _currentSessionType = SessionType.work;
      _isBreakTime = false;
    }

    _setSessionDuration();
  }

  void _showCompletionNotification() {
    String message;
    if (_currentSessionType == SessionType.work) {
      message = _isBreakTime ? '工作完成！开始休息吧' : '番茄钟完成！';
    } else {
      message = '休息结束！准备开始下一个番茄钟';
    }
    
    // TODO: 实现通知显示
    print(message);
  }

  void dispose() {
    _timer?.cancel();
    _listeners.clear();
  }
}

