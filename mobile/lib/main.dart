import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 辅助工具类
class TimerUtils {
  static Color getTimerTypeColor(TimerType type) {
    switch (type) {
      case TimerType.work:
        return Colors.red;
      case TimerType.shortBreak:
        return Colors.green;
      case TimerType.longBreak:
        return Colors.blue;
    }
  }

  static IconData getTimerTypeIcon(TimerType type) {
    switch (type) {
      case TimerType.work:
        return Icons.work;
      case TimerType.shortBreak:
        return Icons.coffee;
      case TimerType.longBreak:
        return Icons.hotel;
    }
  }

  static String getTimerTypeText(TimerType type) {
    switch (type) {
      case TimerType.work:
        return '工作时间';
      case TimerType.shortBreak:
        return '短休息';
      case TimerType.longBreak:
        return '长休息';
    }
  }
}

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

// Project model
class Project {
  final String id;
  final String name;
  final String icon;
  final String color;
  final DateTime createdAt;

  Project({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'color': color,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
    id: json['id'] as String,
    name: json['name'] as String,
    icon: json['icon'] as String,
    color: json['color'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

// Enhanced Task model
class Task {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final DateTime createdAt;
  final TaskPriority priority;
  final String projectId;
  final int plannedPomodoros;
  final int completedPomodoros;
  final DateTime? dueDate;

  Task({
    required this.id,
    required this.title,
    required this.description,
    this.isCompleted = false,
    required this.createdAt,
    this.priority = TaskPriority.medium,
    required this.projectId,
    this.plannedPomodoros = 4,
    this.completedPomodoros = 0,
    this.dueDate,
  });

  Task copyWith({
    String? title,
    String? description,
    bool? isCompleted,
    TaskPriority? priority,
    String? projectId,
    int? plannedPomodoros,
    int? completedPomodoros,
    DateTime? dueDate,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      priority: priority ?? this.priority,
      projectId: projectId ?? this.projectId,
      plannedPomodoros: plannedPomodoros ?? this.plannedPomodoros,
      completedPomodoros: completedPomodoros ?? this.completedPomodoros,
      dueDate: dueDate ?? this.dueDate,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'isCompleted': isCompleted,
    'createdAt': createdAt.toIso8601String(),
    'priority': priority.name,
    'projectId': projectId,
    'plannedPomodoros': plannedPomodoros,
    'completedPomodoros': completedPomodoros,
    'dueDate': dueDate?.toIso8601String(),
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    isCompleted: json['isCompleted'] as bool,
    createdAt: DateTime.parse(json['createdAt'] as String),
    priority: TaskPriority.values.firstWhere(
      (e) => e.name == json['priority'] as String,
      orElse: () => TaskPriority.medium,
    ),
    projectId: json['projectId'] as String,
    plannedPomodoros: (json['plannedPomodoros'] as int?) ?? 4,
    completedPomodoros: (json['completedPomodoros'] as int?) ?? 0,
    dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
  );
}

enum TaskPriority { low, medium, high, urgent }

// Pomodoro Session model
class PomodoroSession {
  final String id;
  final String? taskId;
  final TimerType type;
  final int duration;
  final DateTime startTime;
  final DateTime? endTime;
  final SessionStatus status;

  PomodoroSession({
    required this.id,
    this.taskId,
    required this.type,
    required this.duration,
    required this.startTime,
    this.endTime,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'taskId': taskId,
    'type': type.name,
    'duration': duration,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'status': status.name,
  };

  factory PomodoroSession.fromJson(Map<String, dynamic> json) => PomodoroSession(
    id: json['id'] as String,
    taskId: json['taskId'] as String?,
    type: TimerType.values.firstWhere(
      (e) => e.name == json['type'] as String,
      orElse: () => TimerType.work,
    ),
    duration: json['duration'] as int,
    startTime: DateTime.parse(json['startTime'] as String),
    endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
    status: SessionStatus.values.firstWhere(
      (e) => e.name == json['status'] as String,
      orElse: () => SessionStatus.completed,
    ),
  );
}

enum TimerType { work, shortBreak, longBreak }
enum SessionStatus { active, paused, completed, cancelled }

// Data persistence service
class DataService {
  static const String _projectsKey = 'projects';
  static const String _tasksKey = 'tasks';
  static const String _sessionsKey = 'sessions';

  static Future<List<Project>> loadProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final projectsJson = prefs.getStringList(_projectsKey) ?? [];
    return projectsJson.map((json) => Project.fromJson(jsonDecode(json) as Map<String, dynamic>)).toList();
  }

  static Future<void> saveProjects(List<Project> projects) async {
    final prefs = await SharedPreferences.getInstance();
    final projectsJson = projects.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList(_projectsKey, projectsJson);
  }

  static Future<List<Task>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList(_tasksKey) ?? [];
    return tasksJson.map((json) => Task.fromJson(jsonDecode(json) as Map<String, dynamic>)).toList();
  }

  static Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = tasks.map((t) => jsonEncode(t.toJson())).toList();
    await prefs.setStringList(_tasksKey, tasksJson);
  }

  static Future<List<PomodoroSession>> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionsJson = prefs.getStringList(_sessionsKey) ?? [];
    return sessionsJson.map((json) => PomodoroSession.fromJson(jsonDecode(json) as Map<String, dynamic>)).toList();
  }

  static Future<void> saveSessions(List<PomodoroSession> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionsJson = sessions.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_sessionsKey, sessionsJson);
  }
}

// Project provider
final projectsProvider = StateNotifierProvider<ProjectNotifier, List<Project>>((ref) {
  return ProjectNotifier();
});

class ProjectNotifier extends StateNotifier<List<Project>> {
  ProjectNotifier() : super([]) {
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final projects = await DataService.loadProjects();
    if (projects.isEmpty) {
      // Initialize with default projects
      final defaultProjects = [
        Project(
          id: 'inbox',
          name: 'Inbox',
          icon: '📥',
          color: '#6c757d',
          createdAt: DateTime.now(),
        ),
        Project(
          id: 'work',
          name: 'Work',
          icon: '💼',
          color: '#007bff',
          createdAt: DateTime.now(),
        ),
        Project(
          id: 'personal',
          name: 'Personal',
          icon: '🏠',
          color: '#28a745',
          createdAt: DateTime.now(),
        ),
        Project(
          id: 'study',
          name: 'Study',
          icon: '📚',
          color: '#ffc107',
          createdAt: DateTime.now(),
        ),
      ];
      state = defaultProjects;
      await DataService.saveProjects(defaultProjects);
    } else {
      state = projects;
    }
  }

  Future<void> addProject(String name) async {
    final project = Project(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      icon: '📁', // Default icon
      color: '#6c757d', // Default color
      createdAt: DateTime.now(),
    );
    state = [...state, project];
    await DataService.saveProjects(state);
  }

  Future<void> updateProject(String id, String name) async {
    state = state.map((project) {
      if (project.id == id) {
        return Project(
          id: project.id,
          name: name,
          icon: project.icon,
          color: project.color,
          createdAt: project.createdAt,
        );
      }
      return project;
    }).toList();
    await DataService.saveProjects(state);
  }

  Future<void> deleteProject(String id) async {
    state = state.where((project) => project.id != id).toList();
    await DataService.saveProjects(state);
  }
}

// Task provider
final tasksProvider = StateNotifierProvider<TaskNotifier, List<Task>>((ref) {
  return TaskNotifier();
});

class TaskNotifier extends StateNotifier<List<Task>> {
  TaskNotifier() : super([]) {
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await DataService.loadTasks();
    state = tasks;
  }

  Future<void> addTask(String title, String description, TaskPriority priority, String projectId, int plannedPomodoros, DateTime? dueDate) async {
    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      createdAt: DateTime.now(),
      priority: priority,
      projectId: projectId,
      plannedPomodoros: plannedPomodoros,
      dueDate: dueDate,
    );
    state = [...state, task];
    await DataService.saveTasks(state);
  }

  Future<void> toggleTask(String id) async {
    state = state.map((task) {
      if (task.id == id) {
        return task.copyWith(isCompleted: !task.isCompleted);
      }
      return task;
    }).toList();
    await DataService.saveTasks(state);
  }

  Future<void> deleteTask(String id) async {
    state = state.where((task) => task.id != id).toList();
    await DataService.saveTasks(state);
  }

  Future<void> updateTask(Task updatedTask) async {
    state = state.map((task) {
      if (task.id == updatedTask.id) {
        return updatedTask;
      }
      return task;
    }).toList();
    await DataService.saveTasks(state);
  }

  Future<void> incrementPomodoroCount(String taskId) async {
    state = state.map((task) {
      if (task.id == taskId) {
        return task.copyWith(completedPomodoros: task.completedPomodoros + 1);
      }
      return task;
    }).toList();
    await DataService.saveTasks(state);
  }
}

// Timer provider
final timerProvider = StateNotifierProvider<TimerNotifier, TimerState>((ref) {
  return TimerNotifier(ref);
});

class TimerState {
  final int seconds;
  final bool isRunning;
  final TimerType type;
  final String? currentTaskId;

  TimerState({
    required this.seconds,
    required this.isRunning,
    required this.type,
    this.currentTaskId,
  });

  TimerState copyWith({
    int? seconds,
    bool? isRunning,
    TimerType? type,
    String? currentTaskId,
  }) {
    return TimerState(
      seconds: seconds ?? this.seconds,
      isRunning: isRunning ?? this.isRunning,
      type: type ?? this.type,
      currentTaskId: currentTaskId ?? this.currentTaskId,
    );
  }
}

// 设置状态管理
class SettingsNotifier extends StateNotifier<Map<String, int>> {
  SettingsNotifier() : super({
    'workDuration': 25, // 工作时间（分钟）
    'shortBreakDuration': 5, // 短休息时间（分钟）
    'longBreakDuration': 15, // 长休息时间（分钟）
    'longBreakInterval': 4, // 长休息间隔（工作周期数）
  });

  void updateSetting(String key, int value) {
    state = {...state, key: value};
  }

  int get workDuration => state['workDuration']!;
  int get shortBreakDuration => state['shortBreakDuration']!;
  int get longBreakDuration => state['longBreakDuration']!;
  int get longBreakInterval => state['longBreakInterval']!;
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, Map<String, int>>((ref) {
  return SettingsNotifier();
});

class TimerNotifier extends StateNotifier<TimerState> {
  Timer? _timer;
  final Ref _ref;

  TimerNotifier(this._ref) : super(TimerState(
    seconds: _getInitialDuration(_ref), 
    isRunning: false, 
    type: TimerType.work
  ));

  static int _getInitialDuration(Ref ref) {
    final settings = ref.read(settingsProvider);
    return settings['workDuration']! * 60;
  }

  int _getDurationForType(TimerType type) {
    final settings = _ref.read(settingsProvider);
    switch (type) {
      case TimerType.work:
        return settings['workDuration']! * 60;
      case TimerType.shortBreak:
        return settings['shortBreakDuration']! * 60;
      case TimerType.longBreak:
        return settings['longBreakDuration']! * 60;
    }
  }

  void startTimer({String? taskId}) {
    if (state.isRunning) return;
    
    state = state.copyWith(isRunning: true, currentTaskId: taskId);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.seconds > 0) {
        state = state.copyWith(seconds: state.seconds - 1);
      } else {
        _onTimerComplete();
      }
    });
  }

  void setCurrentTask(String? taskId) {
    state = state.copyWith(currentTaskId: taskId);
  }

  void _checkTimerComplete() {
    final targetDuration = _getDurationForType(state.type);
    if (state.seconds >= targetDuration) {
      _onTimerComplete();
    }
  }

  Future<void> _onTimerComplete() async {
    // 停止计时器
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
    
    // 创建会话记录
    final session = PomodoroSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      taskId: state.currentTaskId,
      type: state.type,
      duration: _getDurationForType(state.type), // 使用完整时长
      startTime: DateTime.now().subtract(Duration(seconds: _getDurationForType(state.type))),
      endTime: DateTime.now(),
      status: SessionStatus.completed,
    );
    
    // 保存会话（这里需要访问 ref，暂时注释）
    // await ref.read(sessionsProvider.notifier).addSession(session);
    
    // 如果是工作会话，增加任务计数（这里需要访问 ref，暂时注释）
    // if (state.type == TimerType.work && state.currentTaskId != null) {
    //   await ref.read(tasksProvider.notifier)
    //       .incrementPomodoroCount(state.currentTaskId!);
    // }
    
    // 自动切换到下一个类型
    _autoSwitchToNextType();
  }

  void _autoSwitchToNextType() {
    TimerType nextType;
    switch (state.type) {
      case TimerType.work:
        nextType = TimerType.shortBreak;
        break;
      case TimerType.shortBreak:
        nextType = TimerType.longBreak;
        break;
      case TimerType.longBreak:
        nextType = TimerType.work;
        break;
    }
    
    setTimerType(nextType);
  }

  void pauseTimer() {
    if (!state.isRunning) return;
    
    state = state.copyWith(isRunning: false);
    _timer?.cancel();
  }

  void resetTimer() {
    final duration = _getDurationForType(state.type);
    state = state.copyWith(seconds: duration, isRunning: false);
    _timer?.cancel();
  }

  void setTimerType(TimerType type) {
    final duration = _getDurationForType(type);
    state = state.copyWith(
      type: type, 
      seconds: duration,
      isRunning: false,
    );
    _timer?.cancel();
  }

  @override
  void updateTimerFromSettings() {
    final currentDuration = _getDurationForType(state.type);
    state = state.copyWith(seconds: currentDuration);
  }

  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// Session provider
final sessionsProvider = StateNotifierProvider<SessionNotifier, List<PomodoroSession>>((ref) {
  return SessionNotifier();
});

class SessionNotifier extends StateNotifier<List<PomodoroSession>> {
  SessionNotifier() : super([]) {
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final sessions = await DataService.loadSessions();
    state = sessions;
  }

  Future<void> addSession(PomodoroSession session) async {
    state = [...state, session];
    await DataService.saveSessions(state);
  }

  Future<void> completeSession(String sessionId) async {
    state = state.map((session) {
      if (session.id == sessionId) {
        return PomodoroSession(
          id: session.id,
          taskId: session.taskId,
          type: session.type,
          duration: session.duration,
          startTime: session.startTime,
          endTime: DateTime.now(),
          status: SessionStatus.completed,
        );
      }
      return session;
    }).toList();
    await DataService.saveSessions(state);
  }
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0; // 0: 任务, 1: 统计, 2: 设置
  String _selectedProjectId = 'inbox';
  bool _isTimerVisible = false; // 控制计时器显示
  
  void switchToTimerTab() {
    setState(() {
      _selectedIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsProvider);
    final tasks = ref.watch(tasksProvider);
    final timerState = ref.watch(timerProvider);
    
    // Get current project name for title
    final currentProject = projects.firstWhere(
      (p) => p.id == _selectedProjectId,
      orElse: () => Project(id: 'inbox', name: '收件箱', icon: '📥', color: '#6c757d', createdAt: DateTime.now()),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle(currentProject.name)),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_selectedIndex == 0) ...[
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddTaskDialog(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.folder),
              onPressed: () => _showProjectSelector(context, ref),
            ),
          ],
        ],
      ),
      body: Row(
        children: [
          // 侧边栏 - 项目管理
          Container(
            width: 200,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                ),
              ),
            ),
            child: Column(
              children: [
                // 项目标题和新建按钮
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.folder_outlined, size: 20, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '项目',
                          style: TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showAddProjectDialog(context, ref),
                        icon: const Icon(Icons.add, size: 18),
                        tooltip: '新建项目',
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          foregroundColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                // 项目列表
                Expanded(
                  child: ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    itemCount: projects.where((p) => p.id != 'inbox').length,
                    onReorder: (oldIndex, newIndex) {
                      final visibleProjects = projects.where((p) => p.id != 'inbox').toList();
                      if (newIndex > oldIndex) newIndex--;
                      final project = visibleProjects.removeAt(oldIndex);
                      visibleProjects.insert(newIndex, project);
                      // TODO: 保存新的顺序到数据库
                    },
                    itemBuilder: (context, index) {
                      final visibleProjects = projects.where((p) => p.id != 'inbox').toList();
                      final project = visibleProjects[index];
                      final isSelected = project.id == _selectedProjectId;
                      final projectTasks = tasks.where((t) => t.projectId == project.id).length;
                      final completedTasks = tasks.where((t) => t.projectId == project.id && t.isCompleted).length;
                      
                      return ReorderableDragStartListener(
                        key: ValueKey(project.id),
                        index: index,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                          dense: true,
                          leading: Text(project.icon, style: const TextStyle(fontSize: 18)),
                          title: Text(
                            project.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            '$completedTasks/$projectTasks',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          trailing: project.id != 'inbox' ? PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert, size: 16),
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditProjectDialog(context, ref, project);
                              } else if (value == 'delete') {
                                _showDeleteProjectDialog(context, ref, project);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 16),
                                    SizedBox(width: 8),
                                    Text('编辑'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 16),
                                    SizedBox(width: 8),
                                    Text('删除'),
                                  ],
                                ),
                              ),
                            ],
                          ) : null,
                          onTap: () {
                            setState(() {
                              _selectedProjectId = project.id;
                              _selectedIndex = 0; // 切换到任务页面
                            });
                          },
                        ),
                        ),
                      );
                    },
                  ),
                ),
                // 导航按钮
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      _buildNavButton(
                        context,
                        Icons.analytics,
                        '统计',
                        1,
                        _selectedIndex == 1,
                      ),
                      const SizedBox(height: 8),
                      _buildNavButton(
                        context,
                        Icons.settings,
                        '设置',
                        2,
                        _selectedIndex == 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          // 主内容区
          Expanded(
            child: Stack(
              children: [
                // 主要内容
                IndexedStack(
                  index: _selectedIndex,
                  children: [
                    TasksScreen(
                      selectedProjectId: _selectedProjectId,
                      onStartPomodoro: () => setState(() => _isTimerVisible = true),
                    ),
                    StatisticsScreen(selectedProjectId: _selectedProjectId),
                    SettingsScreen(),
                  ],
                ),
                // 计时器覆盖层
                if (_isTimerVisible)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.8),
                      child: Center(
                        child: Container(
                          width: 400,
                          height: 500,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // 计时器标题栏
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '番茄钟计时器',
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => setState(() => _isTimerVisible = false),
                                      icon: const Icon(Icons.close),
                                    ),
                                  ],
                                ),
                              ),
                              // 计时器内容
                              Expanded(
                                child: TimerScreen(selectedProjectId: _selectedProjectId),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      // Bottom mini player (only show when timer is running and fullscreen timer is not visible)
      bottomSheet: timerState.isRunning && !_isTimerVisible ? _buildMiniPlayer(context, ref, timerState, () {
        setState(() {
          _isTimerVisible = true;
        });
      }) : null,
    );
  }

  void _showAddTaskDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    TaskPriority selectedPriority = TaskPriority.medium;
    int plannedPomodoros = 4;
    DateTime? dueDate;

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('添加任务'),
          content: SingleChildScrollView(
            child: Column(
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
                  value: selectedPriority,
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
                const SizedBox(height: 16),
                TextField(
                  controller: TextEditingController(text: plannedPomodoros.toString()),
                  decoration: const InputDecoration(
                    labelText: '计划番茄钟数量',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    plannedPomodoros = int.tryParse(value) ?? 4;
                  },
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        dueDate = date;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today),
                        const SizedBox(width: 8),
                        Text(dueDate != null 
                          ? '截止日期: ${dueDate!.toLocal().toString().split(' ')[0]}'
                          : '选择截止日期（可选）'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
                    _selectedProjectId,
                    plannedPomodoros,
                    dueDate,
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

  void _showAddProjectDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加项目'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: '项目名称',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                ref.read(projectsProvider.notifier).addProject(nameController.text);
                Navigator.of(context).pop();
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _showEditProjectDialog(BuildContext context, WidgetRef ref, Project project) {
    final nameController = TextEditingController(text: project.name);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑项目'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: '项目名称',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && nameController.text != project.name) {
                ref.read(projectsProvider.notifier).updateProject(project.id, nameController.text);
                Navigator.of(context).pop();
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showDeleteProjectDialog(BuildContext context, WidgetRef ref, Project project) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除项目'),
        content: Text('确定要删除项目 "${project.name}" 吗？\n\n该项目下的任务将移动到"收件箱"。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              // Move tasks to inbox before deleting project
              final tasks = ref.read(tasksProvider);
              final projectTasks = tasks.where((t) => t.projectId == project.id).toList();
              
              for (final task in projectTasks) {
                ref.read(tasksProvider.notifier).updateTask(
                  task.copyWith(projectId: 'inbox')
                );
              }
              
              ref.read(projectsProvider.notifier).deleteProject(project.id);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showProjectSelector(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider);
    
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择项目'),
        content: SizedBox(
          width: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return ListTile(
                leading: Text(project.icon, style: const TextStyle(fontSize: 20)),
                title: Text(project.name),
                onTap: () {
                  setState(() {
                    _selectedProjectId = project.id;
                  });
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle(String projectName) {
    switch (_selectedIndex) {
      case 0:
        return projectName; // 直接显示项目名称
      case 1:
        return '统计 - $projectName';
      case 2:
        return '设置';
      default:
        return 'Pomodoro Genie';
    }
  }

  String _getTimerTypeText(TimerType type) {
    switch (type) {
      case TimerType.work:
        return '工作时间';
      case TimerType.shortBreak:
        return '短休息';
      case TimerType.longBreak:
        return '长休息';
    }
  }

  Widget _buildNavButton(BuildContext context, IconData icon, String label, int index, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniPlayer(BuildContext context, WidgetRef ref, TimerState timerState, VoidCallback onMaximize) {
    final tasks = ref.watch(tasksProvider);
    final currentTask = timerState.currentTaskId != null 
        ? tasks.firstWhere((t) => t.id == timerState.currentTaskId, orElse: () => Task(
            id: '',
            title: '未知任务',
            description: '',
            createdAt: DateTime.now(),
            priority: TaskPriority.medium,
            projectId: '',
            plannedPomodoros: 4,
          ))
        : null;
    
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Timer display
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: TimerUtils.getTimerTypeColor(timerState.type),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Center(
                child: Text(
                  _formatTime(timerState.seconds),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Task info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    currentTask?.title ?? TimerUtils.getTimerTypeText(timerState.type),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        TimerUtils.getTimerTypeIcon(timerState.type),
                        color: Colors.white70,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        TimerUtils.getTimerTypeText(timerState.type),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Control buttons
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    timerState.isRunning ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    if (timerState.isRunning) {
                      ref.read(timerProvider.notifier).pauseTimer();
                    } else {
                      ref.read(timerProvider.notifier).startTimer(taskId: timerState.currentTaskId);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.fullscreen, color: Colors.white),
                  onPressed: onMaximize,
                ),
              ],
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
  final String selectedProjectId;
  
  const TimerScreen({super.key, required this.selectedProjectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerProvider);
    final timerNotifier = ref.read(timerProvider.notifier);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 状态指示器
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: TimerUtils.getTimerTypeColor(timerState.type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: TimerUtils.getTimerTypeColor(timerState.type),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  TimerUtils.getTimerTypeIcon(timerState.type),
                  color: TimerUtils.getTimerTypeColor(timerState.type),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  TimerUtils.getTimerTypeText(timerState.type),
                  style: TextStyle(
                    color: TimerUtils.getTimerTypeColor(timerState.type),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          
          // Timer display
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: TimerUtils.getTimerTypeColor(timerState.type).withOpacity(0.1),
              border: Border.all(
                color: TimerUtils.getTimerTypeColor(timerState.type),
                width: 4,
              ),
            ),
            child: Center(
              child: Text(
                _formatTime(timerState.seconds),
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: TimerUtils.getTimerTypeColor(timerState.type),
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
                    : () => timerNotifier.startTimer(),
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

  Widget _buildTaskDetailsCard(BuildContext context, WidgetRef ref, String taskId) {
    final tasks = ref.watch(tasksProvider);
    final task = tasks.firstWhere((t) => t.id == taskId, orElse: () => Task(
      id: '',
      title: '未知任务',
      description: '',
      createdAt: DateTime.now(),
      priority: TaskPriority.medium,
      projectId: '',
      plannedPomodoros: 4,
    ));
    
    if (task.id.isEmpty) {
      return const Text('任务未找到');
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.task, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              '当前任务',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          task.title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (task.description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            task.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            const SizedBox(width: 12),
            Text(
              '🍅 ${task.completedPomodoros}/${task.plannedPomodoros}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: task.plannedPomodoros > 0 ? task.completedPomodoros / task.plannedPomodoros : 0,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
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

  Color _getTimerTypeColor(TimerType type) {
    return TimerUtils.getTimerTypeColor(type);
  }

  IconData _getTimerTypeIcon(TimerType type) {
    return TimerUtils.getTimerTypeIcon(type);
  }

  String _getTimerTypeText(TimerType type) {
    return TimerUtils.getTimerTypeText(type);
  }
}

class TasksScreen extends ConsumerWidget {
  final String selectedProjectId;
  final VoidCallback onStartPomodoro;
  
  const TasksScreen({
    super.key, 
    required this.selectedProjectId,
    required this.onStartPomodoro,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);
    final projectTasks = tasks.where((t) => t.projectId == selectedProjectId).toList();
    final completedTasks = projectTasks.where((task) => task.isCompleted).length;
    final totalTasks = projectTasks.length;
    final activeTasks = projectTasks.where((task) => !task.isCompleted).toList();

    return Column(
      children: [
        // 顶部工具栏
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
              ),
            ),
          ),
          child: Row(
            children: [
              // 统计信息
              Expanded(
                child: Row(
                  children: [
                    _buildQuickStat(context, '$totalTasks', '任务', Colors.blue),
                    const SizedBox(width: 16),
                    _buildQuickStat(context, '$completedTasks', '完成', Colors.green),
                    const SizedBox(width: 16),
                    _buildQuickStat(
                      context,
                      totalTasks > 0 ? '${(completedTasks / totalTasks * 100).round()}%' : '0%', 
                      '进度', 
                      Colors.orange
                    ),
                  ],
                ),
              ),
              // 快速添加按钮
              FloatingActionButton.small(
                onPressed: () => _showQuickAddTaskDialog(context, ref),
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
        ),
        // 任务列表
        Expanded(
          child: activeTasks.isEmpty && projectTasks.isNotEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                      SizedBox(height: 16),
                      Text(
                        '所有任务已完成！',
                        style: TextStyle(fontSize: 18, color: Colors.green),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '恭喜你完成了所有任务',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : activeTasks.isEmpty
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
                            '点击 + 按钮快速添加任务',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.all(16),
                      buildDefaultDragHandles: false,
                      itemCount: activeTasks.length,
                      onReorder: (oldIndex, newIndex) {
                        if (newIndex > oldIndex) newIndex--;
                        final task = activeTasks.removeAt(oldIndex);
                        activeTasks.insert(newIndex, task);
                        // TODO: 保存新的顺序到数据库
                      },
                      itemBuilder: (context, index) {
                        final task = activeTasks[index];
                        return ReorderableDragStartListener(
                          key: ValueKey(task.id),
                          index: index,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Checkbox(
                              value: task.isCompleted,
                              onChanged: (value) {
                                ref.read(tasksProvider.notifier).toggleTask(task.id);
                              },
                            ),
                            title: Text(
                              task.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (task.description.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    task.description,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getPriorityColor(task.priority),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _getPriorityText(task.priority),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '🍅 ${task.completedPomodoros}/${task.plannedPomodoros}',
                                        style: TextStyle(
                                          color: Colors.red[700],
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Pomodoro button
                                IconButton(
                                  icon: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                  onPressed: () {
                                    _startPomodoroForTask(context, ref, task);
                                  },
                                ),
                                // More options
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 20),
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showEditTaskDialog(context, ref, task);
                                    } else if (value == 'delete') {
                                      ref.read(tasksProvider.notifier).deleteTask(task.id);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, size: 16),
                                          SizedBox(width: 8),
                                          Text('编辑'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, size: 16),
                                          SizedBox(width: 8),
                                          Text('删除'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildQuickStat(BuildContext context, String value, String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  void _showQuickAddTaskDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    TaskPriority selectedPriority = TaskPriority.medium;
    int plannedPomodoros = 4;

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('快速添加任务'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: '任务标题',
                  border: OutlineInputBorder(),
                  hintText: '输入任务名称...',
                ),
                autofocus: true,
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    ref.read(tasksProvider.notifier).addTask(
                      value,
                      '',
                      selectedPriority,
                      selectedProjectId,
                      plannedPomodoros,
                      null,
                    );
                    Navigator.of(context).pop();
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<TaskPriority>(
                      value: selectedPriority,
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
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(text: plannedPomodoros.toString()),
                      decoration: const InputDecoration(
                        labelText: '番茄钟',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        plannedPomodoros = int.tryParse(value) ?? 4;
                      },
                    ),
                  ),
                ],
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
                    '',
                    selectedPriority,
                    selectedProjectId,
                    plannedPomodoros,
                    null,
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

  void _showEditTaskDialog(BuildContext context, WidgetRef ref, Task task) {
    final titleController = TextEditingController(text: task.title);
    final descriptionController = TextEditingController(text: task.description);
    TaskPriority selectedPriority = task.priority;
    int plannedPomodoros = task.plannedPomodoros;
    DateTime? dueDate = task.dueDate;

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('编辑任务'),
          content: SingleChildScrollView(
            child: Column(
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
                  value: selectedPriority,
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
                const SizedBox(height: 16),
                TextField(
                  controller: TextEditingController(text: plannedPomodoros.toString()),
                  decoration: const InputDecoration(
                    labelText: '计划番茄钟数量',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    plannedPomodoros = int.tryParse(value) ?? 4;
                  },
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: dueDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        dueDate = date;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today),
                        const SizedBox(width: 8),
                        Text(dueDate != null 
                          ? '截止日期: ${dueDate!.toLocal().toString().split(' ')[0]}'
                          : '选择截止日期（可选）'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  final updatedTask = task.copyWith(
                    title: titleController.text,
                    description: descriptionController.text,
                    priority: selectedPriority,
                    plannedPomodoros: plannedPomodoros,
                    dueDate: dueDate,
                  );
                  ref.read(tasksProvider.notifier).updateTask(updatedTask);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  void _startPomodoroForTask(BuildContext context, WidgetRef ref, Task task) {
    // Start timer for the task
    ref.read(timerProvider.notifier).startTimer(taskId: task.id);
    
    // Navigate to timer screen
    onStartPomodoro();
    
    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('开始为任务 "${task.title}" 计时'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class StatisticsScreen extends ConsumerWidget {
  final String selectedProjectId;
  
  const StatisticsScreen({super.key, required this.selectedProjectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);
    final sessions = ref.watch(sessionsProvider);
    final projectTasks = tasks.where((t) => t.projectId == selectedProjectId).toList();
    final completedTasks = projectTasks.where((task) => task.isCompleted).length;
    final totalTasks = projectTasks.length;
    final totalPomodoros = projectTasks.fold(0, (sum, task) => sum + task.completedPomodoros);
    final totalWorkTime = sessions.where((s) => s.type == TimerType.work).fold(0, (sum, s) => sum + s.duration);
    final completionRate = totalTasks > 0 ? (completedTasks / totalTasks * 100).round() : 0;
    final avgEfficiency = totalTasks > 0 ? (totalPomodoros / totalTasks) : 0.0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
            Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.1),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题区域
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.analytics,
                      size: 28,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '统计概览',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '项目进度与效率分析',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // 统计卡片网格
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _buildStatCard(
                    context,
                    '总任务数',
                    '$totalTasks',
                    Icons.task_alt,
                    Colors.blue,
                    '个任务',
                  ),
                  _buildStatCard(
                    context,
                    '已完成',
                    '$completedTasks',
                    Icons.check_circle,
                    Colors.green,
                    '个任务',
                  ),
                  _buildStatCard(
                    context,
                    '完成率',
                    '$completionRate%',
                    Icons.trending_up,
                    Colors.orange,
                    '完成度',
                  ),
                  _buildStatCard(
                    context,
                    '番茄钟',
                    '$totalPomodoros',
                    Icons.timer,
                    Colors.red,
                    '个番茄',
                  ),
                  _buildStatCard(
                    context,
                    '专注时间',
                    '${(totalWorkTime / 60).round()}',
                    Icons.schedule,
                    Colors.purple,
                    '分钟',
                  ),
                  _buildStatCard(
                    context,
                    '平均效率',
                    avgEfficiency.toStringAsFixed(1),
                    Icons.speed,
                    Colors.teal,
                    '番茄/任务',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color, String unit) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              unit,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
            Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.1),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题区域
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.settings,
                      size: 28,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '设置',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '个性化你的番茄钟体验',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // 番茄钟设置
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildSettingsCard(
                      context,
                      '番茄钟时间设置',
                      Icons.timer,
                      [
                        _buildTimeSetting(
                          context,
                          ref,
                          '工作时间',
                          'workDuration',
                          settings['workDuration']!,
                          Icons.work,
                          Colors.blue,
                        ),
                        _buildTimeSetting(
                          context,
                          ref,
                          '短休息时间',
                          'shortBreakDuration',
                          settings['shortBreakDuration']!,
                          Icons.coffee,
                          Colors.green,
                        ),
                        _buildTimeSetting(
                          context,
                          ref,
                          '长休息时间',
                          'longBreakDuration',
                          settings['longBreakDuration']!,
                          Icons.hotel,
                          Colors.orange,
                        ),
                        _buildIntervalSetting(
                          context,
                          ref,
                          '长休息间隔',
                          'longBreakInterval',
                          settings['longBreakInterval']!,
                          Icons.repeat,
                          Colors.purple,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 应用信息
                    _buildSettingsCard(
                      context,
                      '应用信息',
                      Icons.info,
                      [
                        ListTile(
                          leading: Icon(Icons.apps, color: Theme.of(context).colorScheme.primary),
                          title: const Text('Pomodoro Genie'),
                          subtitle: const Text('版本 2.0.0'),
                        ),
                        ListTile(
                          leading: Icon(Icons.code, color: Theme.of(context).colorScheme.secondary),
                          title: const Text('开发信息'),
                          subtitle: const Text('Flutter + Riverpod + SharedPreferences'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTimeSetting(BuildContext context, WidgetRef ref, String title, String key, int value, IconData icon, Color color) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title),
      subtitle: Text('${value}分钟'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: value > 1 ? () {
              ref.read(settingsProvider.notifier).updateSetting(key, value - 1);
              ref.read(timerProvider.notifier).updateTimerFromSettings();
            } : null,
          ),
          Text(
            '$value',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: value < 60 ? () {
              ref.read(settingsProvider.notifier).updateSetting(key, value + 1);
              ref.read(timerProvider.notifier).updateTimerFromSettings();
            } : null,
          ),
        ],
      ),
    );
  }

  Widget _buildIntervalSetting(BuildContext context, WidgetRef ref, String title, String key, int value, IconData icon, Color color) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title),
      subtitle: Text('每${value}个工作周期'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: value > 2 ? () {
              ref.read(settingsProvider.notifier).updateSetting(key, value - 1);
            } : null,
          ),
          Text(
            '$value',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: value < 10 ? () {
              ref.read(settingsProvider.notifier).updateSetting(key, value + 1);
            } : null,
          ),
        ],
      ),
    );
  }
}
