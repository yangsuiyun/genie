import 'package:flutter/material.dart';
import 'dart:async';
import 'settings.dart';
import 'screens/task_screen.dart';
import 'services/task_service.dart';
import 'services/notification_service.dart';
import 'services/session_service.dart';
import 'models/pomodoro_session.dart';

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

  // 状态变化监听器
  final List<VoidCallback> _listeners = [];

  bool get isRunning => _isRunning;
  int get remainingSeconds => _remainingSeconds;
  int get totalSeconds => _totalSeconds;
  double get progress => 1.0 - (_remainingSeconds / _totalSeconds);
  Task? get currentTask => _currentTask;
  PomodoroSession? get currentSession => _currentSession;

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

  void start([Task? task]) async {
    if (_isRunning) return;

    _currentTask = task;
    if (_currentTask != null) {
      // 如果有指定任务，将任务状态设为进行中
      await _taskService.updateTask(_currentTask!.copyWith(status: TaskStatus.inProgress));
    }

    // 创建新的会话记录
    _currentSession = await _sessionService.startSession(
      task: _currentTask,
      plannedDuration: _totalSeconds,
      type: SessionType.work,
    );

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

    // 发送通知
    if (_currentTask != null) {
      _notificationService.showPomodoroCompleted(taskTitle: _currentTask!.title);
      print('Pomodoro completed for task: ${_currentTask!.title}');
    } else {
      _notificationService.showPomodoroCompleted();
      print('Pomodoro completed');
    }

    _currentTask = null;
    _currentSession = null;
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
  }

  Future<void> _initializeServices() async {
    final sessionService = SessionService();
    await sessionService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
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
                        return CircularProgressIndicator(
                          value: _controller.value,
                          strokeWidth: 8,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _pomodoroState.isRunning ? Colors.red : Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                  Text(
                    _pomodoroState.timeDisplay,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 当前任务显示
            if (_pomodoroState.currentTask != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _settings.themeColor.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _settings.themeColor.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.task_alt, color: _settings.themeColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '正在处理: ${_pomodoroState.currentTask!.title}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _settings.themeColor.shade700,
                        ),
                      ),
                    ),
                    Text(
                      _pomodoroState.currentTask!.priorityEmoji,
                      style: const TextStyle(fontSize: 16),
                    ),
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

            // 控制按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _pomodoroState.isRunning ? _pauseTimer : _startTimer,
                  icon: Icon(_pomodoroState.isRunning ? Icons.pause : Icons.play_arrow),
                  label: Text(_pomodoroState.isRunning ? '暂停' : '开始'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _pomodoroState.isRunning ? Colors.orange : Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _resetTimer,
                  icon: const Icon(Icons.refresh),
                  label: const Text('重置'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // 状态信息
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _pomodoroState.isRunning ? Icons.timer : Icons.info_outline,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _pomodoroState.isRunning ? '专注中，保持高效！' : '点击开始，专注工作！',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 通知测试按钮
                  if (!_pomodoroState.isRunning)
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
                        color: Colors.red.shade600,
                      ),
                      label: Text(
                        _notificationService.hasPermission ? '测试通知' : '开启通知',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade600,
                        ),
                      ),
                    ),
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

