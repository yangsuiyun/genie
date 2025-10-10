import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: PomodoroGenieApp()));
}

class PomodoroGenieApp extends StatelessWidget {
  const PomodoroGenieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pomodoro Genie',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

// Task model
class Task {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final DateTime createdAt;
  final TaskPriority priority;

  Task({
    required this.id,
    required this.title,
    required this.description,
    this.isCompleted = false,
    required this.createdAt,
    this.priority = TaskPriority.medium,
  });

  Task copyWith({
    String? title,
    String? description,
    bool? isCompleted,
    TaskPriority? priority,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      priority: priority ?? this.priority,
    );
  }
}

enum TaskPriority { low, medium, high, urgent }

// Task provider
final tasksProvider = StateNotifierProvider<TaskNotifier, List<Task>>((ref) {
  return TaskNotifier();
});

class TaskNotifier extends StateNotifier<List<Task>> {
  TaskNotifier() : super([]);

  void addTask(String title, String description, TaskPriority priority) {
    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      createdAt: DateTime.now(),
      priority: priority,
    );
    state = [...state, task];
  }

  void toggleTask(String id) {
    state = state.map((task) {
      if (task.id == id) {
        return task.copyWith(isCompleted: !task.isCompleted);
      }
      return task;
    }).toList();
  }

  void deleteTask(String id) {
    state = state.where((task) => task.id != id).toList();
  }

  void updateTask(Task updatedTask) {
    state = state.map((task) {
      if (task.id == updatedTask.id) {
        return updatedTask;
      }
      return task;
    }).toList();
  }
}

// Timer provider
final timerProvider = StateNotifierProvider<TimerNotifier, TimerState>((ref) {
  return TimerNotifier();
});

class TimerState {
  final int seconds;
  final bool isRunning;
  final TimerType type;

  TimerState({
    required this.seconds,
    required this.isRunning,
    required this.type,
  });

  TimerState copyWith({
    int? seconds,
    bool? isRunning,
    TimerType? type,
  }) {
    return TimerState(
      seconds: seconds ?? this.seconds,
      isRunning: isRunning ?? this.isRunning,
      type: type ?? this.type,
    );
  }
}

enum TimerType { work, shortBreak, longBreak }

class TimerNotifier extends StateNotifier<TimerState> {
  Timer? _timer;

  TimerNotifier() : super(TimerState(seconds: 0, isRunning: false, type: TimerType.work));

  void startTimer() {
    if (state.isRunning) return;
    
    state = state.copyWith(isRunning: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      state = state.copyWith(seconds: state.seconds + 1);
    });
  }

  void pauseTimer() {
    if (!state.isRunning) return;
    
    state = state.copyWith(isRunning: false);
    _timer?.cancel();
  }

  void resetTimer() {
    state = state.copyWith(seconds: 0, isRunning: false);
    _timer?.cancel();
  }

  void setTimerType(TimerType type) {
    final duration = _getDurationForType(type);
    state = state.copyWith(type: type, seconds: duration);
  }

  int _getDurationForType(TimerType type) {
    switch (type) {
      case TimerType.work:
        return 25 * 60; // 25 minutes
      case TimerType.shortBreak:
        return 5 * 60; // 5 minutes
      case TimerType.longBreak:
        return 15 * 60; // 15 minutes
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(tasksProvider);
    final timerState = ref.watch(timerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pomodoro Genie'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_selectedIndex == 1)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddTaskDialog(context, ref),
            ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          TimerScreen(),
          TasksScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.timer),
            label: '计时器',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task),
            label: '任务',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    TaskPriority selectedPriority = TaskPriority.medium;

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('添加任务'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: '任务标题',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: '任务描述',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TaskPriority>(
                initialValue: selectedPriority,
                decoration: const InputDecoration(
                  labelText: '优先级',
                  border: OutlineInputBorder(),
                ),
                items: TaskPriority.values.map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Text(_getPriorityText(priority)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedPriority = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  ref.read(tasksProvider.notifier).addTask(
                    titleController.text,
                    descriptionController.text,
                    selectedPriority,
                  );
                  Navigator.of(context).pop();
                }
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }

  static String _getPriorityText(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return '低';
      case TaskPriority.medium:
        return '中';
      case TaskPriority.high:
        return '高';
      case TaskPriority.urgent:
        return '紧急';
    }
  }
}

class TimerScreen extends ConsumerWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerProvider);
    final timerNotifier = ref.read(timerProvider.notifier);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Timer type selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTimerTypeButton(
                context,
                ref,
                TimerType.work,
                '工作',
                Colors.red,
                Icons.work,
              ),
              const SizedBox(width: 16),
              _buildTimerTypeButton(
                context,
                ref,
                TimerType.shortBreak,
                '短休息',
                Colors.green,
                Icons.coffee,
              ),
              const SizedBox(width: 16),
              _buildTimerTypeButton(
                context,
                ref,
                TimerType.longBreak,
                '长休息',
                Colors.blue,
                Icons.hotel,
              ),
            ],
          ),
          const SizedBox(height: 40),
          
          // Timer display
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Center(
              child: Text(
                _formatTime(timerState.seconds),
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          
          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: timerState.isRunning 
                    ? timerNotifier.pauseTimer 
                    : timerNotifier.startTimer,
                icon: Icon(timerState.isRunning ? Icons.pause : Icons.play_arrow),
                label: Text(timerState.isRunning ? '暂停' : '开始'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: timerState.isRunning ? Colors.orange : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              const SizedBox(width: 20),
              ElevatedButton.icon(
                onPressed: timerNotifier.resetTimer,
                icon: const Icon(Icons.stop),
                label: const Text('重置'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          
          // Status card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.timer,
                    color: Theme.of(context).colorScheme.primary,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pomodoro 计时器',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '专注工作 ${_formatTime(timerState.seconds)}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerTypeButton(
    BuildContext context,
    WidgetRef ref,
    TimerType type,
    String label,
    Color color,
    IconData icon,
  ) {
    final timerState = ref.watch(timerProvider);
    final isSelected = timerState.type == type;

    return GestureDetector(
      onTap: () {
        ref.read(timerProvider.notifier).setTimerType(type);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);
    final completedTasks = tasks.where((task) => task.isCompleted).length;
    final totalTasks = tasks.length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('总任务', totalTasks.toString(), Icons.task),
                  _buildStatItem('已完成', completedTasks.toString(), Icons.check_circle),
                  _buildStatItem('进度', totalTasks > 0 ? '${(completedTasks / totalTasks * 100).round()}%' : '0%', Icons.trending_up),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Tasks list
          Expanded(
            child: tasks.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.task_alt, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          '还没有任务',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '点击右上角的 + 按钮添加任务',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Checkbox(
                            value: task.isCompleted,
                            onChanged: (value) {
                              ref.read(tasksProvider.notifier).toggleTask(task.id);
                            },
                          ),
                          title: Text(
                            task.title,
                            style: TextStyle(
                              decoration: task.isCompleted 
                                  ? TextDecoration.lineThrough 
                                  : null,
                            ),
                          ),
                          subtitle: task.description.isNotEmpty
                              ? Text(task.description)
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getPriorityColor(task.priority),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getPriorityText(task.priority),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  ref.read(tasksProvider.notifier).deleteTask(task.id);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.deepPurple),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
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

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.urgent:
        return Colors.purple;
    }
  }

  String _getPriorityText(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return '低';
      case TaskPriority.medium:
        return '中';
      case TaskPriority.high:
        return '高';
      case TaskPriority.urgent:
        return '紧急';
    }
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '设置',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // App info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.info, size: 48, color: Colors.blue),
                  const SizedBox(height: 16),
                  Text(
                    'Pomodoro Genie',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('版本 1.0.0'),
                  const SizedBox(height: 16),
                  const Text(
                    '一个简单而有效的 Pomodoro 计时器和任务管理应用。\n\n'
                    '功能特点：\n'
                    '• Pomodoro 计时器（25分钟工作，5分钟短休息，15分钟长休息）\n'
                    '• 任务管理（添加、完成、删除任务）\n'
                    '• 优先级设置（低、中、高、紧急）\n'
                    '• 进度跟踪\n'
                    '• 响应式设计',
                    style: TextStyle(height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Development info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.code, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        '开发信息',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Flutter 版本: 3.35.6'),
                  const Text('Dart 版本: 3.9.2'),
                  const Text('状态管理: Riverpod 2.6.1'),
                  const Text('UI 框架: Material 3'),
                  const SizedBox(height: 16),
                  const Text(
                    '这是一个演示版本，展示了 Flutter Web 应用的基本功能。'
                    '可以在此基础上继续开发更多高级功能。',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
