import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  return TimerNotifier();
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

class TimerNotifier extends StateNotifier<TimerState> {
  Timer? _timer;

  TimerNotifier() : super(TimerState(seconds: 0, isRunning: false, type: TimerType.work));

  void startTimer({String? taskId}) {
    if (state.isRunning) return;
    
    state = state.copyWith(isRunning: true, currentTaskId: taskId);
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
  int _selectedIndex = 0;
  String _selectedProjectId = 'inbox';
  
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
          if (_selectedIndex == 1)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddTaskDialog(context, ref),
            ),
          if (_selectedIndex == 0)
            IconButton(
              icon: const Icon(Icons.folder),
              onPressed: () => _showProjectSelector(context, ref),
            ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 200,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Projects',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: projects.length,
                    itemBuilder: (context, index) {
                      final project = projects[index];
                      final isSelected = project.id == _selectedProjectId;
                      final projectTasks = tasks.where((t) => t.projectId == project.id).length;
                      
                      return ListTile(
                        leading: Text(project.icon, style: const TextStyle(fontSize: 20)),
                        title: Text(project.name),
                        subtitle: Text('$projectTasks tasks'),
                        selected: isSelected,
                        trailing: project.id != 'inbox' ? PopupMenuButton<String>(
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
                                  Icon(Icons.edit),
                                  SizedBox(width: 8),
                                  Text('编辑'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete),
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
                          });
                        },
                      );
                    },
                  ),
                ),
                // Add Project Button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddProjectDialog(context, ref),
                      icon: const Icon(Icons.add),
                      label: const Text('添加项目'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                TimerScreen(selectedProjectId: _selectedProjectId),
                TasksScreen(
                  selectedProjectId: _selectedProjectId,
                  onStartPomodoro: switchToTimerTab,
                ),
                SettingsScreen(),
              ],
            ),
          ),
        ],
      ),
      // Bottom mini player (only show when timer is running)
      bottomSheet: timerState.isRunning ? _buildMiniPlayer(context, ref, timerState) : null,
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
        return '计时器 - $projectName';
      case 1:
        return '任务 - $projectName';
      case 2:
        return '设置';
      default:
        return 'Pomodoro Genie';
    }
  }

  Widget _buildMiniPlayer(BuildContext context, WidgetRef ref, TimerState timerState) {
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
                color: Colors.red,
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
                    currentTask?.title ?? '番茄钟',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _getTimerTypeText(timerState.type),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
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
                  onPressed: () {
                    // Switch to timer tab
                    setState(() {
                      _selectedIndex = 0;
                    });
                  },
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
    final tasks = ref.watch(tasksProvider);
    final projectTasks = tasks.where((t) => t.projectId == selectedProjectId && !t.isCompleted).toList();

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
          
          // Task selector for work mode
          if (timerState.type == TimerType.work && projectTasks.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  const Text('选择任务:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: timerState.currentTaskId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: projectTasks.map((task) {
                      return DropdownMenuItem(
                        value: task.id,
                        child: Text(task.title),
                      );
                    }).toList(),
                    onChanged: (taskId) {
                      // Task selection will be handled when starting timer
                    },
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 20),
          
          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: timerState.isRunning 
                    ? timerNotifier.pauseTimer 
                    : () => timerNotifier.startTimer(
                        taskId: timerState.type == TimerType.work 
                            ? timerState.currentTaskId 
                            : null,
                      ),
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
              if (timerState.isRunning && timerState.type != TimerType.work) ...[
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    // Skip break and go to work
                    timerNotifier.setTimerType(TimerType.work);
                    timerNotifier.startTimer(taskId: timerState.currentTaskId);
                  },
                  icon: const Icon(Icons.skip_next),
                  label: const Text('跳过休息'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
              if (timerState.isRunning) ...[
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    // Switch to tasks tab to show mini player
                    DefaultTabController.of(context)?.animateTo(1);
                  },
                  icon: const Icon(Icons.fullscreen_exit),
                  label: const Text('缩小'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 40),
          
          // Task details card (only show when timer is running with a task)
          if (timerState.isRunning && timerState.currentTaskId != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
              ),
              child: _buildTaskDetailsCard(context, ref, timerState.currentTaskId!),
            ),
          
          const SizedBox(height: 20),
          
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
            child: projectTasks.isEmpty
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
                    itemCount: projectTasks.length,
                    itemBuilder: (context, index) {
                      final task = projectTasks[index];
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
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (task.description.isNotEmpty)
                                Text(task.description),
                              const SizedBox(height: 4),
                              Row(
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
                                  Text(
                                    '🍅 ${task.completedPomodoros}/${task.plannedPomodoros}',
                                    style: const TextStyle(fontSize: 12),
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
                                    size: 20,
                                  ),
                                ),
                                onPressed: () {
                                  _startPomodoroForTask(context, ref, task);
                                },
                              ),
                              // Delete button
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
                  const Text('版本 2.0.0'),
                  const SizedBox(height: 16),
                  const Text(
                    '功能特点：\n'
                    '• 项目管理系统\n'
                    '• 任务与番茄钟关联\n'
                    '• 数据持久化存储\n'
                    '• 优先级管理\n'
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
                  const Text('数据存储: SharedPreferences'),
                  const SizedBox(height: 16),
                  const Text(
                    '这是一个功能完整的 Pomodoro 应用，支持项目管理和数据持久化。'
                    '所有数据都会自动保存到本地存储中。',
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
