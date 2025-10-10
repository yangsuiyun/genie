import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/index.dart';
import '../screens/main_layout.dart';
import 'platform_storage.dart';

class TaskService {
  static final TaskService _instance = TaskService._internal();
  factory TaskService() => _instance;
  TaskService._internal();

  static const String _storageKey = 'pomodoro_tasks';
  List<Task> _tasks = [];
  final List<VoidCallback> _listeners = [];
  final PlatformStorage _storage = PlatformStorage();

  // 获取所有任务
  List<Task> get tasks => List.unmodifiable(_tasks);

  // 获取所有任务（用于Provider）
  List<Task> getAllTasks() {
    return List.unmodifiable(_tasks);
  }

  // 根据时间过滤器获取任务
  List<Task> getTasksByTimeFilter(TaskTimeFilter filter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final weekEnd = today.add(Duration(days: 7 - today.weekday));

    switch (filter) {
      case TaskTimeFilter.today:
        return _tasks.where((t) {
          if (t.dueDate == null) return false;
          return t.dueDate!.isBefore(tomorrow) && !t.isCompleted;
        }).toList();

      case TaskTimeFilter.tomorrow:
        return _tasks.where((t) {
          if (t.dueDate == null) return false;
          final dueDay = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
          return dueDay.isAtSameMomentAs(tomorrow) && !t.isCompleted;
        }).toList();

      case TaskTimeFilter.thisWeek:
        return _tasks.where((t) {
          if (t.dueDate == null) return false;
          return t.dueDate!.isBefore(weekEnd) && !t.isCompleted;
        }).toList();

      case TaskTimeFilter.planned:
        return _tasks.where((t) => !t.isCompleted).toList();

      case TaskTimeFilter.completed:
        return _tasks.where((t) => t.isCompleted).toList();
    }
  }

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

  // 初始化，从本地存储加载数据
  Future<void> initialize() async {
    await _loadFromStorage();

    // 如果没有任务，创建一些示例任务
    if (_tasks.isEmpty) {
      _createSampleTasks();
      await _saveToStorage();
    }
  }

  // 创建示例任务
  void _createSampleTasks() {
    _tasks = [
      Task.create(
        title: '完成项目文档',
        description: '编写API文档和用户手册',
        priority: TaskPriority.high,
        dueDate: DateTime.now().add(const Duration(days: 1)),
        tags: ['工作', '文档'],
        plannedPomodoros: 6,
      ).copyWith(
        subtasks: [
          Subtask.create('编写API文档'),
          Subtask.create('编写用户手册'),
          Subtask.create('Review和修改'),
        ],
      ),
      Task.create(
        title: '优化数据库查询',
        description: '提高API响应速度',
        priority: TaskPriority.medium,
        dueDate: DateTime.now().add(const Duration(days: 3)),
        tags: ['开发', '性能'],
        plannedPomodoros: 4,
      ),
      Task.create(
        title: '学习Flutter状态管理',
        description: '深入了解Riverpod和Provider',
        priority: TaskPriority.low,
        tags: ['学习', 'Flutter'],
        plannedPomodoros: 3,
      ),
    ];
  }

  // 获取任务按状态筛选
  List<Task> getTasksByStatus(TaskStatus? status) {
    if (status == null) return tasks;
    return _tasks.where((task) => task.status == status).toList();
  }

  // 获取任务按优先级筛选
  List<Task> getTasksByPriority(TaskPriority? priority) {
    if (priority == null) return tasks;
    return _tasks.where((task) => task.priority == priority).toList();
  }

  // 获取即将到期的任务
  List<Task> getUpcomingTasks() {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));

    return _tasks.where((task) {
      return task.dueDate != null &&
          task.dueDate!.isAfter(now) &&
          task.dueDate!.isBefore(tomorrow) &&
          !task.isCompleted;
    }).toList();
  }

  // 获取过期任务
  List<Task> getOverdueTasks() {
    return _tasks.where((task) => task.isOverdue).toList();
  }

  // 添加任务
  Future<Task> addTask(Task task) async {
    _tasks.add(task);
    await _saveToStorage();
    _notifyListeners();
    return task;
  }

  // 更新任务
  Future<Task> updateTask(Task updatedTask) async {
    final index = _tasks.indexWhere((task) => task.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      await _saveToStorage();
      _notifyListeners();
      return updatedTask;
    }
    throw Exception('Task not found');
  }

  // 删除任务
  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((task) => task.id == taskId);
    await _saveToStorage();
    _notifyListeners();
  }

  // 切换任务完成状态
  Future<Task> toggleTaskCompletion(String taskId) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    final newStatus = task.isCompleted ? TaskStatus.pending : TaskStatus.completed;
    return await updateTask(task.copyWith(status: newStatus));
  }

  // 添加子任务
  Future<Task> addSubtask(String taskId, String subtaskTitle) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    final newSubtasks = [...task.subtasks, Subtask.create(subtaskTitle)];
    return await updateTask(task.copyWith(subtasks: newSubtasks));
  }

  // 切换子任务完成状态
  Future<Task> toggleSubtaskCompletion(String taskId, String subtaskId) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    final newSubtasks = task.subtasks.map((subtask) {
      if (subtask.id == subtaskId) {
        return subtask.copyWith(
          status: subtask.status == TaskStatus.completed 
            ? TaskStatus.pending 
            : TaskStatus.completed,
        );
      }
      return subtask;
    }).toList();
    return await updateTask(task.copyWith(subtasks: newSubtasks));
  }

  // 获取任务统计
  TaskStatistics getStatistics() {
    final total = _tasks.length;
    final completed = _tasks.where((t) => t.isCompleted).length;
    final pending = _tasks.where((t) => t.status == TaskStatus.pending).length;
    final inProgress = _tasks.where((t) => t.status == TaskStatus.inProgress).length;
    final overdue = _tasks.where((t) => t.isOverdue).length;

    return TaskStatistics(
      total: total,
      completed: completed,
      pending: pending,
      inProgress: inProgress,
      overdue: overdue,
    );
  }

  // 搜索任务
  List<Task> searchTasks(String query) {
    if (query.isEmpty) return tasks;

    final lowerQuery = query.toLowerCase();
    return _tasks.where((task) {
      return task.title.toLowerCase().contains(lowerQuery) ||
          task.description.toLowerCase().contains(lowerQuery) ||
          task.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  // 从本地存储加载
  Future<void> _loadFromStorage() async {
    try {
      final tasksJson = _storage.getItem(_storageKey);

      if (tasksJson != null && tasksJson.isNotEmpty) {
        final List<dynamic> tasksList = json.decode(tasksJson);
        _tasks = tasksList.map((taskJson) => Task.fromJson(taskJson)).toList();
      }
    } catch (e) {
      print('Error loading tasks from storage: $e');
      _tasks = [];
    }
  }

  // 保存到本地存储
  Future<void> _saveToStorage() async {
    try {
      final tasksJson = json.encode(_tasks.map((task) => task.toJson()).toList());
      _storage.setItem(_storageKey, tasksJson);
    } catch (e) {
      print('Error saving tasks to storage: $e');
    }
  }

  // 导出数据
  String exportData() {
    return json.encode({
      'tasks': _tasks.map((task) => task.toJson()).toList(),
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0',
    });
  }

  // 导入数据
  Future<bool> importData(String jsonData) async {
    try {
      final data = json.decode(jsonData);
      final List<dynamic> tasksList = data['tasks'];
      _tasks = tasksList.map((taskJson) => Task.fromJson(taskJson)).toList();
      await _saveToStorage();
      _notifyListeners();
      return true;
    } catch (e) {
      print('Error importing data: $e');
      return false;
    }
  }

  // 清除所有数据
  Future<void> clearAllData() async {
    _tasks.clear();
    _storage.removeItem(_storageKey);
    _notifyListeners();
  }

  // 清除所有任务 (别名方法，用于兼容)
  Future<void> clearAllTasks() async {
    await clearAllData();
  }
}

class TaskStatistics {
  final int total;
  final int completed;
  final int pending;
  final int inProgress;
  final int overdue;

  TaskStatistics({
    required this.total,
    required this.completed,
    required this.pending,
    required this.inProgress,
    required this.overdue,
  });

  double get completionRate => total > 0 ? completed / total : 0.0;
}