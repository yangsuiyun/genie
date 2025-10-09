import 'package:flutter/material.dart';
import 'dart:async';
import 'settings.dart';
import 'screens/task_screen.dart';
import 'services/task_service.dart';
import 'services/notification_service.dart';
import 'services/session_service.dart';
import 'services/sync_service.dart';
import 'models/index.dart';

void main() {
  runApp(const PomodoroApp());
}

class PomodoroApp extends StatelessWidget {
  const PomodoroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pomodoro Genie',
      theme: ThemeData(
        primarySwatch: Colors.red,
        useMaterial3: true,
      ),
      home: MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// 全局状态管理
class PomodoroState {
  static final PomodoroState _instance = PomodoroState._internal();
  factory PomodoroState() => _instance;
  PomodoroState._internal();

  Timer? _timer;
  bool _isRunning = false;
  int _remainingSeconds = 25 * 60; // 25分钟 = 1500秒
  int _totalSeconds = 25 * 60;
  final AppSettings _settings = AppSettings();

  // 当前正在处理的任务
  Task? _currentTask;
  final TaskService _taskService = TaskService();
  final NotificationService _notificationService = NotificationService();
  final SessionService _sessionService = SessionService();

  // 当前会话
  PomodoroSession? _currentSession;

  // 番茄钟循环管理
  int _completedPomodoros = 0;
  bool _isBreakTime = false;
  SessionType _currentSessionType = SessionType.work;

  // 状态变化监听器
  final List<VoidCallback> _listeners = [];

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

    // 确定会话类型
    if (sessionType != null) {
      _currentSessionType = sessionType;
    } else if (!_isBreakTime) {
      _currentSessionType = SessionType.work;
    }

    // 根据会话类型设置时长
    switch (_currentSessionType) {
      case SessionType.work:
        _totalSeconds = _settings.workDuration * 60;
        _isBreakTime = false;
        _currentTask = task;
        if (_currentTask != null) {
          // 如果有指定任务，将任务状态设为进行中
          await _taskService.updateTask(_currentTask!.copyWith(status: TaskStatus.inProgress));
        }
        break;
      case SessionType.shortBreak:
        _totalSeconds = _settings.shortBreak * 60;
        _isBreakTime = true;
        _currentTask = null; // 休息时不关联任务
        break;
      case SessionType.longBreak:
        _totalSeconds = _settings.longBreak * 60;
        _isBreakTime = true;
        _currentTask = null; // 休息时不关联任务
        break;
    }

    _remainingSeconds = _totalSeconds;

    // 创建新的会话记录
    _currentSession = await _sessionService.startSession(
      task: _currentTask,
      plannedDuration: _totalSeconds,
      type: _currentSessionType,
    );

    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        _notifyListeners();
      } else {
        // 会话结束
        _complete();
      }
    });
    _notifyListeners();
  }

  void pause() async {
    _isRunning = false;
    _timer?.cancel();
    _timer = null;

    // 暂停当前会话
    if (_currentSession != null) {
      await _sessionService.pauseSession(_currentSession!.id);
    }

    _notifyListeners();
  }

  void reset() async {
    _isRunning = false;
    _timer?.cancel();
    _timer = null;

    // 如果有活动会话，中断它
    if (_currentSession != null) {
      final elapsedSeconds = _totalSeconds - _remainingSeconds;
      await _sessionService.interruptSession(
        _currentSession!.id,
        actualDuration: elapsedSeconds,
        notes: '用户手动重置',
      );
    }

    _totalSeconds = _settings.workDuration * 60;
    _remainingSeconds = _totalSeconds;
    _currentTask = null; // 清除当前任务
    _currentSession = null; // 清除当前会话
    _notifyListeners();
  }

  void resume() async {
    if (_isRunning) return;

    // 恢复当前会话
    if (_currentSession != null) {
      await _sessionService.resumeSession(_currentSession!.id);
    }

    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        _notifyListeners();
      } else {
        // 番茄钟结束
        _complete();
      }
    });
    _notifyListeners();
  }

  void updateFromSettings() {
    if (!_isRunning) {
      _totalSeconds = _settings.workDuration * 60;
      _remainingSeconds = _totalSeconds;
      _notifyListeners();
    }
  }

  void _complete() async {
    _isRunning = false;
    _timer?.cancel();
    _timer = null;
    _remainingSeconds = 0;

    // 完成当前会话
    if (_currentSession != null) {
      await _sessionService.completeSession(
        _currentSession!.id,
        actualDuration: _totalSeconds,
        notes: '正常完成',
      );
    }

    // 根据会话类型处理完成逻辑
    if (_currentSessionType == SessionType.work) {
      // 工作会话完成，增加完成的番茄钟数量
      _completedPomodoros++;

      // 发送工作完成通知
      if (_currentTask != null) {
        _notificationService.showPomodoroCompleted(taskTitle: _currentTask!.title);
        print('Work session completed for task: ${_currentTask!.title}');
      } else {
        _notificationService.showPomodoroCompleted();
        print('Work session completed');
      }

      // 准备休息建议
      _suggestBreak();
    } else {
      // 休息会话完成
      _isBreakTime = false;

      // 发送休息完成通知
      String breakType = _currentSessionType == SessionType.shortBreak ? '短休息' : '长休息';
      _notificationService.showBreakCompleted(breakType: breakType);
      print('$breakType completed');

      // 重置为工作模式
      _currentSessionType = SessionType.work;
      _totalSeconds = _settings.workDuration * 60;
      _remainingSeconds = _totalSeconds;

      // 自动开始下一个番茄钟（如果设置了自动开始）
      if (_settings.autoStartPomodoros) {
        // 延迟一秒后自动开始，给用户时间看到完成状态
        Timer(const Duration(seconds: 1), () {
          start();
        });
      }
    }

    _currentTask = null;
    _currentSession = null;
    _notifyListeners();
  }

  void _suggestBreak() {
    // 根据完成的番茄钟数量建议休息
    if (_completedPomodoros % _settings.longBreakInterval == 0) {
      // 长休息时间
      _currentSessionType = SessionType.longBreak;
      print('建议长休息 ${_settings.longBreak} 分钟');
    } else {
      // 短休息时间
      _currentSessionType = SessionType.shortBreak;
      print('建议短休息 ${_settings.shortBreak} 分钟');
    }

    // 设置休息时长
    switch (_currentSessionType) {
      case SessionType.shortBreak:
        _totalSeconds = _settings.shortBreak * 60;
        break;
      case SessionType.longBreak:
        _totalSeconds = _settings.longBreak * 60;
        break;
      case SessionType.work:
        break; // 不会到这里
    }

    _remainingSeconds = _totalSeconds;
    _isBreakTime = true;

    // 自动开始休息（如果设置了自动开始）
    if (_settings.autoStartBreaks) {
      // 延迟一秒后自动开始休息
      Timer(const Duration(seconds: 1), () {
        start(null, _currentSessionType);
      });
    }
  }

  // 手动开始休息
  void startBreak({SessionType? breakType}) {
    if (_isRunning) return;

    final sessionType = breakType ??
        ((_completedPomodoros % _settings.longBreakInterval == 0)
            ? SessionType.longBreak
            : SessionType.shortBreak);

    start(null, sessionType);
  }

  // 跳过休息，直接开始下一个工作会话
  void skipBreak() {
    if (_isRunning) return;

    _isBreakTime = false;
    _currentSessionType = SessionType.work;
    _totalSeconds = _settings.workDuration * 60;
    _remainingSeconds = _totalSeconds;
    _notifyListeners();
  }

  void dispose() {
    _timer?.cancel();
    _listeners.clear();
  }
}

class MainScreen extends StatefulWidget {
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late List<Widget> _screens;
  final SyncService _syncService = SyncService();
  Timer? _syncCheckTimer;

  @override
  void initState() {
    super.initState();
    // 初始化会话服务
    _initializeServices();

    // 使用同一个PomodoroTimerScreen实例来保持状态
    _screens = [
      const PomodoroTimerScreen(),
      const TaskScreen(),
      const ReportsScreen(),
      const SettingsScreen(),
    ];

    // 定期检查同步状态
    _syncCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _syncService.checkConnectivity().then((_) {
          if (mounted) setState(() {});
        });
      }
    });
  }

  Future<void> _initializeServices() async {
    final sessionService = SessionService();
    await sessionService.initialize();

    // 初始化同步服务
    await _syncService.initialize();
  }

  @override
  void dispose() {
    _syncCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
          // 同步状态浮动指示器
          Positioned(
            top: 50,
            right: 16,
            child: _buildSyncIndicator(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.timer),
            label: '番茄钟',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_alt),
            label: '任务',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: '报告',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }

  Widget _buildSyncIndicator() {
    return AnimatedBuilder(
      animation: Listenable.merge([]),
      builder: (context, child) {
        final isOnline = _syncService.isOnline;
        final isSyncing = _syncService.isSyncInProgress;

        if (!isOnline && !isSyncing) {
          return const SizedBox.shrink(); // 离线且未同步时不显示
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSyncing ? Colors.orange : (isOnline ? Colors.green : Colors.grey),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSyncing)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                Icon(
                  isOnline ? Icons.cloud_done : Icons.cloud_off,
                  size: 12,
                  color: Colors.white,
                ),
              const SizedBox(width: 4),
              Text(
                isSyncing ? '同步' : (isOnline ? '在线' : '离线'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// 番茄钟主界面
class PomodoroTimerScreen extends StatefulWidget {
  const PomodoroTimerScreen({super.key});

  @override
  State<PomodoroTimerScreen> createState() => _PomodoroTimerScreenState();
}

class _PomodoroTimerScreenState extends State<PomodoroTimerScreen>
    with TickerProviderStateMixin {
  final PomodoroState _pomodoroState = PomodoroState();
  final AppSettings _settings = AppSettings();
  final TaskService _taskService = TaskService();
  final NotificationService _notificationService = NotificationService();
  late AnimationController _controller;
  List<Task> _availableTasks = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(minutes: 25),
    );

    // 监听状态变化
    _pomodoroState.addListener(_onStateChanged);
    _settings.addListener(_onSettingsChanged);
    _taskService.addListener(_onTasksChanged);

    // 初始化动画状态
    _updateAnimationProgress();
    _initializeTasks();
    _initializeNotifications();
  }

  Future<void> _initializeTasks() async {
    await _taskService.initialize();
    _loadAvailableTasks();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
  }

  void _loadAvailableTasks() {
    setState(() {
      _availableTasks = _taskService.getTasksByStatus(null)
          .where((task) => !task.isCompleted)
          .toList();
    });
  }

  void _onTasksChanged() {
    if (mounted) {
      _loadAvailableTasks();
    }
  }

  @override
  void dispose() {
    _pomodoroState.removeListener(_onStateChanged);
    _settings.removeListener(_onSettingsChanged);
    _taskService.removeListener(_onTasksChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {});
      _updateAnimationProgress();
    }
  }

  void _onSettingsChanged() {
    _pomodoroState.updateFromSettings();
    if (mounted) {
      setState(() {});
    }
  }

  void _updateAnimationProgress() {
    _controller.animateTo(_pomodoroState.progress);
  }

  void _startTimer() {
    _pomodoroState.start();
  }

  void _pauseTimer() {
    _pomodoroState.pause();
  }

  void _resetTimer() {
    _pomodoroState.reset();
  }

  void _showTaskSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择任务'),
        content: SizedBox(
          width: double.maxFinite,
          child: _availableTasks.isEmpty
              ? const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.task_alt, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('暂无可用任务'),
                    Text('请先在任务页面添加任务', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _availableTasks.length,
                  itemBuilder: (context, index) {
                    final task = _availableTasks[index];
                    return ListTile(
                      leading: Text(task.priorityEmoji, style: const TextStyle(fontSize: 20)),
                      title: Text(task.title),
                      subtitle: task.description.isNotEmpty ? Text(task.description) : null,
                      trailing: Text(task.statusEmoji, style: const TextStyle(fontSize: 20)),
                      onTap: () {
                        Navigator.pop(context);
                        _startTimerWithTask(task);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          if (_availableTasks.isNotEmpty)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _startTimerWithTask(null);
              },
              child: const Text('不选择任务'),
            ),
        ],
      ),
    );
  }

  void _startTimerWithTask(Task? task) {
    _pomodoroState.start(task);
  }

  String _formatTaskDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;

    if (difference < 0) {
      return '已过期 ${-difference} 天';
    } else if (difference == 0) {
      return '今天到期';
    } else if (difference == 1) {
      return '明天到期';
    } else {
      return '$difference 天后到期';
    }
  }

  void _markTaskCompleted() {
    if (_pomodoroState.currentTask != null) {
      final updatedTask = _pomodoroState.currentTask!.copyWith(
        status: TaskStatus.completed,
      );
      _taskService.updateTask(updatedTask);
      _pomodoroState.reset(); // 重置计时器状态

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('任务"${updatedTask.title}"已标记为完成！'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: '撤销',
            textColor: Colors.white,
            onPressed: () {
              // 撤销完成状态
              _taskService.updateTask(updatedTask.copyWith(status: TaskStatus.inProgress));
            },
          ),
        ),
      );
    }
  }

  void _showTaskQuickNotes() {
    final TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加任务备注'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('为任务"${_pomodoroState.currentTask!.title}"添加备注'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                hintText: '输入备注内容...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final notes = notesController.text.trim();
              if (notes.isNotEmpty) {
                // 这里可以扩展Task模型来支持备注，目前添加到描述中
                final currentDescription = _pomodoroState.currentTask!.description;
                final newDescription = currentDescription.isEmpty
                    ? '备注: $notes'
                    : '$currentDescription\n\n备注: $notes';

                final updatedTask = _pomodoroState.currentTask!.copyWith(
                  description: newDescription,
                );
                _taskService.updateTask(updatedTask);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('备注已添加'),
                    backgroundColor: Colors.blue,
                  ),
                );
              }
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🍅 Pomodoro Genie'),
        backgroundColor: _settings.themeColor.shade400,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 番茄钟计数显示
            if (_pomodoroState.completedPomodoros > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _settings.themeColor.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _settings.themeColor.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department,
                         color: _settings.themeColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '已完成 ${_pomodoroState.completedPomodoros} 个番茄钟',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _settings.themeColor.shade700,
                      ),
                    ),
                  ],
                ),
              ),

            // 圆形计时器
            SizedBox(
              width: 250,
              height: 250,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 250,
                    height: 250,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        Color timerColor;
                        if (_pomodoroState.currentSessionType == SessionType.work) {
                          timerColor = _pomodoroState.isRunning ? Colors.red : Colors.grey;
                        } else if (_pomodoroState.currentSessionType == SessionType.shortBreak) {
                          timerColor = _pomodoroState.isRunning ? Colors.green : Colors.grey;
                        } else {
                          timerColor = _pomodoroState.isRunning ? Colors.blue : Colors.grey;
                        }

                        return CircularProgressIndicator(
                          value: _controller.value,
                          strokeWidth: 8,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                        );
                      },
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _pomodoroState.timeDisplay,
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: _pomodoroState.currentSessionType == SessionType.work
                              ? Colors.red
                              : _pomodoroState.currentSessionType == SessionType.shortBreak
                                  ? Colors.green
                                  : Colors.blue,
                        ),
                      ),
                      if (_pomodoroState.currentSessionType != SessionType.work)
                        Text(
                          _pomodoroState.currentSessionType == SessionType.shortBreak
                              ? '短休息时间'
                              : '长休息时间',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _pomodoroState.currentSessionType == SessionType.shortBreak
                                ? Colors.green.shade600
                                : Colors.blue.shade600,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 当前任务显示
            if (_pomodoroState.currentTask != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _settings.themeColor.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _settings.themeColor.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.task_alt, color: _settings.themeColor, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '正在处理',
                            style: TextStyle(
                              fontSize: 12,
                              color: _settings.themeColor.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          _pomodoroState.currentTask!.priorityEmoji,
                          style: const TextStyle(fontSize: 18),
                        ),
                        Text(
                          _pomodoroState.currentTask!.statusEmoji,
                          style: const TextStyle(fontSize: 18),
                        ),
                        if (!_pomodoroState.isRunning)
                          IconButton(
                            icon: const Icon(Icons.swap_horiz, size: 18),
                            onPressed: _showTaskSelectionDialog,
                            tooltip: '切换任务',
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            padding: const EdgeInsets.all(4),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _pomodoroState.currentTask!.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _settings.themeColor.shade800,
                      ),
                    ),
                    if (_pomodoroState.currentTask!.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _pomodoroState.currentTask!.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: _settings.themeColor.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (_pomodoroState.currentTask!.subtasks.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.checklist,
                            size: 14,
                            color: _settings.themeColor.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_pomodoroState.currentTask!.completedSubtasks}/${_pomodoroState.currentTask!.subtasks.length} 子任务完成',
                            style: TextStyle(
                              fontSize: 11,
                              color: _settings.themeColor.shade600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: _pomodoroState.currentTask!.progress,
                              backgroundColor: _settings.themeColor.shade200,
                              valueColor: AlwaysStoppedAnimation(_settings.themeColor),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_pomodoroState.currentTask!.dueDate != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 12,
                            color: _pomodoroState.currentTask!.isOverdue ? Colors.red : Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTaskDueDate(_pomodoroState.currentTask!.dueDate!),
                            style: TextStyle(
                              fontSize: 10,
                              color: _pomodoroState.currentTask!.isOverdue ? Colors.red : Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

            // 任务选择按钮
            if (_pomodoroState.currentTask == null && !_pomodoroState.isRunning)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton.icon(
                  onPressed: _showTaskSelectionDialog,
                  icon: const Icon(Icons.add_task),
                  label: const Text('选择任务开始番茄钟'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _settings.themeColor.shade100,
                    foregroundColor: _settings.themeColor.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // 休息建议通知
            if (_pomodoroState.isBreakTime && !_pomodoroState.isRunning)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _pomodoroState.currentSessionType == SessionType.shortBreak
                        ? [Colors.green.shade50, Colors.green.shade100]
                        : [Colors.blue.shade50, Colors.blue.shade100],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _pomodoroState.currentSessionType == SessionType.shortBreak
                        ? Colors.green.shade200
                        : Colors.blue.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.coffee,
                          color: _pomodoroState.currentSessionType == SessionType.shortBreak
                              ? Colors.green.shade600
                              : Colors.blue.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _pomodoroState.currentSessionType == SessionType.shortBreak
                              ? '建议短休息 ${_settings.shortBreak} 分钟'
                              : '建议长休息 ${_settings.longBreak} 分钟',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _pomodoroState.currentSessionType == SessionType.shortBreak
                                ? Colors.green.shade700
                                : Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '您已完成一个番茄钟，适当休息有助于保持专注力！',
                      style: TextStyle(
                        fontSize: 12,
                        color: _pomodoroState.currentSessionType == SessionType.shortBreak
                            ? Colors.green.shade600
                            : Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ),

            // 控制按钮
            if (_pomodoroState.isBreakTime && !_pomodoroState.isRunning)
              // 休息控制按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pomodoroState.startBreak(),
                    icon: const Icon(Icons.coffee),
                    label: Text(_pomodoroState.currentSessionType == SessionType.shortBreak ? '开始短休息' : '开始长休息'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _pomodoroState.currentSessionType == SessionType.shortBreak
                          ? Colors.green
                          : Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _pomodoroState.skipBreak(),
                    icon: const Icon(Icons.skip_next),
                    label: const Text('跳过休息'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              )
            else
              // 正常工作/休息控制按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _pomodoroState.isRunning ? _pauseTimer : _startTimer,
                    icon: Icon(_pomodoroState.isRunning ? Icons.pause : Icons.play_arrow),
                    label: Text(_pomodoroState.isRunning ? '暂停' : '开始'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _pomodoroState.currentSessionType == SessionType.work
                          ? (_pomodoroState.isRunning ? Colors.orange : Colors.green)
                          : _pomodoroState.currentSessionType == SessionType.shortBreak
                              ? Colors.green
                              : Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _resetTimer,
                    icon: const Icon(Icons.refresh),
                    label: const Text('重置'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 30),

            // 状态信息和会话信息
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: _pomodoroState.isRunning
                    ? (_pomodoroState.currentSessionType == SessionType.work
                        ? Colors.red.shade50
                        : _pomodoroState.currentSessionType == SessionType.shortBreak
                            ? Colors.green.shade50
                            : Colors.blue.shade50)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _pomodoroState.isRunning
                      ? (_pomodoroState.currentSessionType == SessionType.work
                          ? Colors.red.shade200
                          : _pomodoroState.currentSessionType == SessionType.shortBreak
                              ? Colors.green.shade200
                              : Colors.blue.shade200)
                      : Colors.grey.shade200,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _pomodoroState.isRunning
                            ? Icons.timer
                            : _pomodoroState.isBreakTime
                                ? Icons.coffee
                                : Icons.info_outline,
                        color: _pomodoroState.isRunning
                            ? (_pomodoroState.currentSessionType == SessionType.work
                                ? Colors.red
                                : _pomodoroState.currentSessionType == SessionType.shortBreak
                                    ? Colors.green
                                    : Colors.blue)
                            : _pomodoroState.isBreakTime
                                ? (_pomodoroState.currentSessionType == SessionType.shortBreak
                                    ? Colors.green.shade600
                                    : Colors.blue.shade600)
                                : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _pomodoroState.isRunning
                            ? (_pomodoroState.currentSessionType == SessionType.work
                                ? '专注中，保持高效！'
                                : _pomodoroState.currentSessionType == SessionType.shortBreak
                                    ? '短休息中，放松身心！'
                                    : '长休息中，好好放松！')
                            : _pomodoroState.isBreakTime
                                ? '休息时间到了！'
                                : '点击开始，专注工作！',
                        style: TextStyle(
                          fontSize: 16,
                          color: _pomodoroState.isRunning
                              ? (_pomodoroState.currentSessionType == SessionType.work
                                  ? Colors.red
                                  : _pomodoroState.currentSessionType == SessionType.shortBreak
                                      ? Colors.green
                                      : Colors.blue)
                              : _pomodoroState.isBreakTime
                                  ? (_pomodoroState.currentSessionType == SessionType.shortBreak
                                      ? Colors.green.shade600
                                      : Colors.blue.shade600)
                                  : Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  // 番茄钟进度指示器
                  if (_pomodoroState.completedPomodoros > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _settings.themeColor.shade200),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '番茄钟周期进度',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _settings.themeColor.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(_settings.longBreakInterval, (index) {
                              final completed = index < (_pomodoroState.completedPomodoros % _settings.longBreakInterval);
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: completed ? _settings.themeColor : Colors.grey.shade300,
                                  shape: BoxShape.circle,
                                ),
                                child: completed
                                    ? const Icon(Icons.check, size: 10, color: Colors.white)
                                    : null,
                              );
                            }),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_pomodoroState.completedPomodoros % _settings.longBreakInterval}/${_settings.longBreakInterval} 完成',
                            style: TextStyle(
                              fontSize: 10,
                              color: _settings.themeColor.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // 当前会话信息
                  if (_pomodoroState.currentSession != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '当前会话',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                              Text(
                                _pomodoroState.currentSession!.typeEmoji,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '计划时长',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                _pomodoroState.currentSession!.plannedDurationDisplay,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '已进行',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                '${(_pomodoroState.totalSeconds - _pomodoroState.remainingSeconds) ~/ 60}:${((_pomodoroState.totalSeconds - _pomodoroState.remainingSeconds) % 60).toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),
                  // 通知测试按钮或快速任务操作
                  if (!_pomodoroState.isRunning) ...[
                    if (_pomodoroState.currentTask != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton.icon(
                            onPressed: () => _markTaskCompleted(),
                            icon: const Icon(Icons.check_circle, size: 16),
                            label: const Text('完成任务', style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.green.shade600,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _showTaskQuickNotes(),
                            icon: const Icon(Icons.note_add, size: 16),
                            label: const Text('添加备注', style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blue.shade600,
                            ),
                          ),
                        ],
                      )
                    else
                      TextButton.icon(
                        onPressed: () async {
                          if (_notificationService.hasPermission) {
                            await _notificationService.showNotification(
                              title: '🔔 测试通知',
                              body: '通知功能正常工作！',
                              duration: 3000,
                            );
                          } else {
                            final granted = await _notificationService.requestPermission();
                            if (granted) {
                              await _notificationService.showNotification(
                                title: '🔔 通知权限已获取',
                                body: '现在可以接收番茄钟通知了！',
                                duration: 3000,
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('通知权限被拒绝，无法发送通知'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        },
                        icon: Icon(
                          _notificationService.hasPermission
                              ? Icons.notifications
                              : Icons.notifications_off,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        label: Text(
                          _notificationService.hasPermission ? '测试通知' : '开启通知',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// 报告界面
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final SessionService _sessionService = SessionService();
  final TaskService _taskService = TaskService();
  final AppSettings _settings = AppSettings();

  late SessionStatistics _sessionStats;
  late TaskStatistics _taskStats;
  late Map<String, dynamic> _insights;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  void _loadStatistics() {
    setState(() {
      _sessionStats = _sessionService.getStatistics();
      _taskStats = _taskService.getStatistics();
      _insights = _sessionService.getProductivityInsights();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 统计报告'),
        backgroundColor: _settings.themeColor.shade400,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
            tooltip: '刷新数据',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadStatistics();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 今日概览
            _buildSectionHeader('今日概览'),
            _buildStatCard(
              '今日完成',
              _sessionStats.todaySessions.toString(),
              '个番茄钟',
              Colors.red,
              icon: Icons.timer,
            ),
            _buildStatCard(
              '专注时间',
              _sessionStats.todayFocusTimeDisplay,
              '',
              Colors.green,
              icon: Icons.schedule,
            ),
            _buildStatCard(
              '完成任务',
              _taskStats.completed.toString(),
              '个任务',
              Colors.blue,
              icon: Icons.task_alt,
            ),
            _buildStatCard(
              '完成率',
              '${(_sessionStats.completionRate * 100).toStringAsFixed(1)}',
              '%',
              Colors.orange,
              icon: Icons.analytics,
            ),

            const SizedBox(height: 24),

            // 总体统计
            _buildSectionHeader('总体统计'),
            _buildStatCard(
              '总会话数',
              _sessionStats.totalSessions.toString(),
              '次',
              Colors.purple,
              icon: Icons.history,
            ),
            _buildStatCard(
              '总专注时间',
              _sessionStats.totalFocusTimeDisplay,
              '',
              Colors.teal,
              icon: Icons.hourglass_bottom,
            ),
            _buildStatCard(
              '平均会话',
              _sessionStats.averageSessionTimeDisplay,
              '',
              Colors.indigo,
              icon: Icons.trending_up,
            ),

            const SizedBox(height: 24),

            // 生产力洞察
            _buildSectionHeader('生产力洞察'),
            _buildInsightCard(),

            const SizedBox(height: 24),

            // 本周趋势
            _buildSectionHeader('本周趋势'),
            _buildWeeklyTrendCard(),

            const SizedBox(height: 24),

            // 时间分布
            _buildSectionHeader('专注时间分布'),
            _buildTimeDistributionCard(),

            const SizedBox(height: 24),

            // 任务统计
            _buildSectionHeader('任务统计'),
            _buildTaskOverview(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: _settings.themeColor.shade700,
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String unit, Color color, {IconData? icon}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(icon ?? Icons.analytics, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      if (unit.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Text(
                          unit,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard() {
    final streakDays = _insights['streakDays'] as int;
    final bestHour = _insights['bestWorkingHour'] as int?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: _settings.themeColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  '洞察分析',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _settings.themeColor.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (streakDays > 0)
              Row(
                children: [
                  const Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Text('已连续专注 $streakDays 天！', style: const TextStyle(fontSize: 14)),
                ],
              ),
            if (bestHour != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.schedule, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Text('最佳工作时间：${bestHour}:00 - ${bestHour + 1}:00',
                         style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            if (streakDays == 0 && bestHour == null)
              const Text(
                '开始使用番茄钟来获得更多洞察！',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyTrendCard() {
    // 获取最近7天的数据
    final weeklyData = _sessionService.getWeeklyTrend();
    final maxSessions = weeklyData.values.reduce((a, b) => a > b ? a : b);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: _settings.themeColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  '最近7天',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _settings.themeColor.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 简单的柱状图
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weeklyData.entries.map((entry) {
                final dayIndex = entry.key;
                final sessions = entry.value;
                final dayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
                final height = maxSessions > 0 ? (sessions / maxSessions * 80).clamp(4.0, 80.0) : 4.0;

                return Column(
                  children: [
                    Container(
                      width: 24,
                      height: height,
                      decoration: BoxDecoration(
                        color: _settings.themeColor.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dayNames[dayIndex],
                      style: const TextStyle(fontSize: 10),
                    ),
                    Text(
                      sessions.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _settings.themeColor,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text(
              '平均每天 ${(weeklyData.values.reduce((a, b) => a + b) / 7).toStringAsFixed(1)} 个番茄钟',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeDistributionCard() {
    final hourlyData = _sessionService.getHourlyDistribution();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: _settings.themeColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  '时间分析',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _settings.themeColor.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 最佳工作时间
            if (_insights['bestWorkingHour'] != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '最佳专注时间: ${_insights['bestWorkingHour']}:00-${_insights['bestWorkingHour'] + 1}:00',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // 时间分布网格
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                childAspectRatio: 1,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: 24,
              itemBuilder: (context, index) {
                final hour = index;
                final sessions = hourlyData[hour] ?? 0;
                final maxHourlySessions = hourlyData.values.isNotEmpty
                    ? hourlyData.values.reduce((a, b) => a > b ? a : b)
                    : 1;
                final intensity = sessions / maxHourlySessions;

                return Container(
                  decoration: BoxDecoration(
                    color: _settings.themeColor.withOpacity(intensity * 0.8),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _settings.themeColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      hour.toString().padLeft(2, '0'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: intensity > 0.5 ? Colors.white : _settings.themeColor.shade700,
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _settings.themeColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                const Text('少', style: TextStyle(fontSize: 10)),
                const SizedBox(width: 16),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _settings.themeColor.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                const Text('多', style: TextStyle(fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskOverview() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.task, color: _settings.themeColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  '任务概览',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _settings.themeColor.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat('总数', _taskStats.total.toString(), Icons.list_alt),
                _buildMiniStat('进行中', _taskStats.inProgress.toString(), Icons.play_circle),
                _buildMiniStat('待开始', _taskStats.pending.toString(), Icons.schedule),
                if (_taskStats.overdue > 0)
                  _buildMiniStat('过期', _taskStats.overdue.toString(), Icons.warning, Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon, [Color? color]) {
    final statColor = color ?? _settings.themeColor;
    return Column(
      children: [
        Icon(icon, color: statColor, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: statColor,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

