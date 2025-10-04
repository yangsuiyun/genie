import 'package:flutter/material.dart';
import 'dart:async';
import 'settings.dart';

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

  // 状态变化监听器
  final List<VoidCallback> _listeners = [];

  bool get isRunning => _isRunning;
  int get remainingSeconds => _remainingSeconds;
  int get totalSeconds => _totalSeconds;
  double get progress => 1.0 - (_remainingSeconds / _totalSeconds);

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

  void start() {
    if (_isRunning) return;

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

  void pause() {
    _isRunning = false;
    _timer?.cancel();
    _timer = null;
    _notifyListeners();
  }

  void reset() {
    _isRunning = false;
    _timer?.cancel();
    _timer = null;
    _totalSeconds = _settings.workDuration * 60;
    _remainingSeconds = _totalSeconds;
    _notifyListeners();
  }

  void updateFromSettings() {
    if (!_isRunning) {
      _totalSeconds = _settings.workDuration * 60;
      _remainingSeconds = _totalSeconds;
      _notifyListeners();
    }
  }

  void _complete() {
    _isRunning = false;
    _timer?.cancel();
    _timer = null;
    _remainingSeconds = 0;
    _notifyListeners();
    // 这里可以触发通知或其他完成逻辑
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
    // 使用同一个PomodoroTimerScreen实例来保持状态
    _screens = [
      const PomodoroTimerScreen(),
      const TaskListScreen(),
      const ReportsScreen(),
      const SettingsScreen(),
    ];
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
  late AnimationController _controller;

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

    // 初始化动画状态
    _updateAnimationProgress();
  }

  @override
  void dispose() {
    _pomodoroState.removeListener(_onStateChanged);
    _settings.removeListener(_onSettingsChanged);
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
            const SizedBox(height: 50),

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
              child: Row(
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
            ),
          ],
        ),
      ),
    );
  }
}

// 任务列表界面
class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📋 我的任务'),
        backgroundColor: Colors.blue.shade400,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTaskCard('完成项目文档', '编写API文档和用户手册', '高', true),
          _buildTaskCard('优化数据库查询', '提高API响应速度', '中', false),
          _buildTaskCard('测试新功能', '进行全面的功能测试', '低', false),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('添加新任务功能开发中...')),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTaskCard(String title, String description, String priority, bool completed) {
    Color priorityColor = priority == '高' ? Colors.red :
                         priority == '中' ? Colors.orange : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Checkbox(
          value: completed,
          onChanged: (value) {},
        ),
        title: Text(
          title,
          style: TextStyle(
            decoration: completed ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(description),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: priorityColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            priority,
            style: TextStyle(
              color: priorityColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

// 报告界面
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 统计报告'),
        backgroundColor: Colors.purple.shade400,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatCard('今日完成', '3', '个番茄钟', Colors.red),
          _buildStatCard('专注时间', '75', '分钟', Colors.green),
          _buildStatCard('完成任务', '2', '个任务', Colors.blue),
          _buildStatCard('效率评分', '85', '分', Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String unit, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(Icons.analytics, color: color, size: 30),
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        unit,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
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
}

