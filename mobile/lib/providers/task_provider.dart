import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import '../services/local_storage.dart';

enum TaskStatus { pending, inProgress, completed, cancelled }

enum TaskPriority { low, medium, high, urgent }

class Task {
  final String id;
  final String title;
  final String? description;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? dueDate;
  final List<String> tags;
  final String? parentTaskId;
  final int estimatedPomodoros;
  final int completedPomodoros;
  final bool isRecurring;
  final Map<String, dynamic>? recurrenceRule;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.status = TaskStatus.pending,
    this.priority = TaskPriority.medium,
    this.dueDate,
    this.tags = const [],
    this.parentTaskId,
    this.estimatedPomodoros = 1,
    this.completedPomodoros = 0,
    this.isRecurring = false,
    this.recurrenceRule,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        status: TaskStatus.values.firstWhere(
          (e) => e.toString().split('.').last == json['status'],
          orElse: () => TaskStatus.pending,
        ),
        priority: TaskPriority.values.firstWhere(
          (e) => e.toString().split('.').last == json['priority'],
          orElse: () => TaskPriority.medium,
        ),
        dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
        tags: List<String>.from(json['tags'] ?? []),
        parentTaskId: json['parent_task_id'],
        estimatedPomodoros: json['estimated_pomodoros'] ?? 1,
        completedPomodoros: json['completed_pomodoros'] ?? 0,
        isRecurring: json['is_recurring'] ?? false,
        recurrenceRule: json['recurrence_rule'],
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'status': status.toString().split('.').last,
        'priority': priority.toString().split('.').last,
        'due_date': dueDate?.toIso8601String(),
        'tags': tags,
        'parent_task_id': parentTaskId,
        'estimated_pomodoros': estimatedPomodoros,
        'completed_pomodoros': completedPomodoros,
        'is_recurring': isRecurring,
        'recurrence_rule': recurrenceRule,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? dueDate,
    List<String>? tags,
    String? parentTaskId,
    int? estimatedPomodoros,
    int? completedPomodoros,
    bool? isRecurring,
    Map<String, dynamic>? recurrenceRule,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Task(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        status: status ?? this.status,
        priority: priority ?? this.priority,
        dueDate: dueDate ?? this.dueDate,
        tags: tags ?? this.tags,
        parentTaskId: parentTaskId ?? this.parentTaskId,
        estimatedPomodoros: estimatedPomodoros ?? this.estimatedPomodoros,
        completedPomodoros: completedPomodoros ?? this.completedPomodoros,
        isRecurring: isRecurring ?? this.isRecurring,
        recurrenceRule: recurrenceRule ?? this.recurrenceRule,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  bool get isCompleted => status == TaskStatus.completed;
  bool get isOverdue => dueDate != null && dueDate!.isBefore(DateTime.now()) && !isCompleted;
  bool get isDueToday => dueDate != null &&
      dueDate!.year == DateTime.now().year &&
      dueDate!.month == DateTime.now().month &&
      dueDate!.day == DateTime.now().day;
  bool get isDueSoon => dueDate != null &&
      dueDate!.isAfter(DateTime.now()) &&
      dueDate!.isBefore(DateTime.now().add(const Duration(days: 3)));
}

class Subtask {
  final String id;
  final String taskId;
  final String title;
  final bool isCompleted;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  Subtask({
    required this.id,
    required this.taskId,
    required this.title,
    this.isCompleted = false,
    this.order = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Subtask.fromJson(Map<String, dynamic> json) => Subtask(
        id: json['id'],
        taskId: json['task_id'],
        title: json['title'],
        isCompleted: json['is_completed'] ?? false,
        order: json['order'] ?? 0,
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'task_id': taskId,
        'title': title,
        'is_completed': isCompleted,
        'order': order,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  Subtask copyWith({
    String? id,
    String? taskId,
    String? title,
    bool? isCompleted,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Subtask(
        id: id ?? this.id,
        taskId: taskId ?? this.taskId,
        title: title ?? this.title,
        isCompleted: isCompleted ?? this.isCompleted,
        order: order ?? this.order,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

class TaskFilter {
  final TaskStatus? status;
  final TaskPriority? priority;
  final List<String>? tags;
  final String? search;
  final DateTime? dueBefore;
  final DateTime? dueAfter;
  final bool? isOverdue;

  TaskFilter({
    this.status,
    this.priority,
    this.tags,
    this.search,
    this.dueBefore,
    this.dueAfter,
    this.isOverdue,
  });

  TaskFilter copyWith({
    TaskStatus? status,
    TaskPriority? priority,
    List<String>? tags,
    String? search,
    DateTime? dueBefore,
    DateTime? dueAfter,
    bool? isOverdue,
  }) =>
      TaskFilter(
        status: status ?? this.status,
        priority: priority ?? this.priority,
        tags: tags ?? this.tags,
        search: search ?? this.search,
        dueBefore: dueBefore ?? this.dueBefore,
        dueAfter: dueAfter ?? this.dueAfter,
        isOverdue: isOverdue ?? this.isOverdue,
      );

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};

    if (status != null) params['status'] = status.toString().split('.').last;
    if (priority != null) params['priority'] = priority.toString().split('.').last;
    if (tags != null && tags!.isNotEmpty) params['tags'] = tags!.join(',');
    if (search != null && search!.isNotEmpty) params['search'] = search;
    if (dueBefore != null) params['due_before'] = dueBefore!.toIso8601String();
    if (dueAfter != null) params['due_after'] = dueAfter!.toIso8601String();
    if (isOverdue != null) params['is_overdue'] = isOverdue;

    return params;
  }
}

enum TaskSortBy { title, priority, dueDate, createdAt, updatedAt }
enum SortOrder { asc, desc }

class TaskSort {
  final TaskSortBy sortBy;
  final SortOrder order;

  TaskSort({
    this.sortBy = TaskSortBy.updatedAt,
    this.order = SortOrder.desc,
  });

  TaskSort copyWith({
    TaskSortBy? sortBy,
    SortOrder? order,
  }) =>
      TaskSort(
        sortBy: sortBy ?? this.sortBy,
        order: order ?? this.order,
      );

  Map<String, dynamic> toQueryParams() => {
        'sort_by': sortBy.toString().split('.').last,
        'sort_order': order.toString().split('.').last,
      };
}

class TaskNotifier extends StateNotifier<AsyncValue<List<Task>>> {
  TaskNotifier() : super(const AsyncValue.loading()) {
    _initialize();
  }

  final ApiClient _apiClient = ApiClient.instance;
  final LocalStorage _localStorage = LocalStorage.instance;

  TaskFilter _currentFilter = TaskFilter();
  TaskSort _currentSort = TaskSort();

  Future<void> _initialize() async {
    await _localStorage.initialize();
    await loadTasks();
  }

  Future<void> loadTasks({
    TaskFilter? filter,
    TaskSort? sort,
    bool forceRefresh = false,
  }) async {
    if (filter != null) _currentFilter = filter;
    if (sort != null) _currentSort = sort;

    try {
      if (!forceRefresh) {
        // Load from local storage first
        final localTasks = _localStorage.getAllTasks()
            .map((taskData) => Task.fromJson(taskData))
            .toList();

        if (localTasks.isNotEmpty) {
          final filteredTasks = _applyFiltersAndSorting(localTasks);
          state = AsyncValue.data(filteredTasks);
        }
      }

      // Fetch from server
      final queryParams = {
        ..._currentFilter.toQueryParams(),
        ..._currentSort.toQueryParams(),
      };

      final response = await _apiClient.get('/tasks', queryParameters: queryParams);

      if (response.isSuccess) {
        final tasks = (response.data['tasks'] as List)
            .map((taskData) => Task.fromJson(taskData))
            .toList();

        // Save to local storage
        final tasksData = tasks.map((task) => task.toJson()).toList();
        await _localStorage.saveTasks(tasksData);

        state = AsyncValue.data(tasks);
      } else {
        throw Exception(response.error ?? 'Failed to load tasks');
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  List<Task> _applyFiltersAndSorting(List<Task> tasks) {
    var filteredTasks = tasks.where((task) {
      if (_currentFilter.status != null && task.status != _currentFilter.status) {
        return false;
      }
      if (_currentFilter.priority != null && task.priority != _currentFilter.priority) {
        return false;
      }
      if (_currentFilter.tags != null && _currentFilter.tags!.isNotEmpty) {
        if (!_currentFilter.tags!.any((tag) => task.tags.contains(tag))) {
          return false;
        }
      }
      if (_currentFilter.search != null && _currentFilter.search!.isNotEmpty) {
        final searchLower = _currentFilter.search!.toLowerCase();
        if (!task.title.toLowerCase().contains(searchLower) &&
            (task.description == null || !task.description!.toLowerCase().contains(searchLower))) {
          return false;
        }
      }
      if (_currentFilter.dueBefore != null && task.dueDate != null) {
        if (!task.dueDate!.isBefore(_currentFilter.dueBefore!)) {
          return false;
        }
      }
      if (_currentFilter.dueAfter != null && task.dueDate != null) {
        if (!task.dueDate!.isAfter(_currentFilter.dueAfter!)) {
          return false;
        }
      }
      if (_currentFilter.isOverdue == true && !task.isOverdue) {
        return false;
      }
      return true;
    }).toList();

    // Apply sorting
    filteredTasks.sort((a, b) {
      int comparison = 0;

      switch (_currentSort.sortBy) {
        case TaskSortBy.title:
          comparison = a.title.compareTo(b.title);
          break;
        case TaskSortBy.priority:
          comparison = a.priority.index.compareTo(b.priority.index);
          break;
        case TaskSortBy.dueDate:
          if (a.dueDate == null && b.dueDate == null) {
            comparison = 0;
          } else if (a.dueDate == null) {
            comparison = 1;
          } else if (b.dueDate == null) {
            comparison = -1;
          } else {
            comparison = a.dueDate!.compareTo(b.dueDate!);
          }
          break;
        case TaskSortBy.createdAt:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case TaskSortBy.updatedAt:
          comparison = a.updatedAt.compareTo(b.updatedAt);
          break;
      }

      return _currentSort.order == SortOrder.desc ? -comparison : comparison;
    });

    return filteredTasks;
  }

  Future<Task?> createTask({
    required String title,
    String? description,
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
    List<String> tags = const [],
    String? parentTaskId,
    int estimatedPomodoros = 1,
    bool isRecurring = false,
    Map<String, dynamic>? recurrenceRule,
  }) async {
    try {
      final response = await _apiClient.post('/tasks', data: {
        'title': title,
        'description': description,
        'priority': priority.toString().split('.').last,
        'due_date': dueDate?.toIso8601String(),
        'tags': tags,
        'parent_task_id': parentTaskId,
        'estimated_pomodoros': estimatedPomodoros,
        'is_recurring': isRecurring,
        'recurrence_rule': recurrenceRule,
      });

      if (response.isSuccess) {
        final task = Task.fromJson(response.data);

        // Save to local storage
        await _localStorage.saveTask(task.id, task.toJson());

        // Update state
        await loadTasks();

        return task;
      } else {
        throw Exception(response.error ?? 'Failed to create task');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Task?> updateTask(String taskId, {
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? dueDate,
    List<String>? tags,
    int? estimatedPomodoros,
    int? completedPomodoros,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (status != null) updateData['status'] = status.toString().split('.').last;
      if (priority != null) updateData['priority'] = priority.toString().split('.').last;
      if (dueDate != null) updateData['due_date'] = dueDate.toIso8601String();
      if (tags != null) updateData['tags'] = tags;
      if (estimatedPomodoros != null) updateData['estimated_pomodoros'] = estimatedPomodoros;
      if (completedPomodoros != null) updateData['completed_pomodoros'] = completedPomodoros;

      final response = await _apiClient.put('/tasks/$taskId', data: updateData);

      if (response.isSuccess) {
        final task = Task.fromJson(response.data);

        // Save to local storage
        await _localStorage.saveTask(task.id, task.toJson());

        // Update state
        await loadTasks();

        return task;
      } else {
        throw Exception(response.error ?? 'Failed to update task');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deleteTask(String taskId) async {
    try {
      final response = await _apiClient.delete('/tasks/$taskId');

      if (response.isSuccess) {
        // Remove from local storage
        await _localStorage.deleteTask(taskId);

        // Update state
        await loadTasks();

        return true;
      } else {
        throw Exception(response.error ?? 'Failed to delete task');
      }
    } catch (e) {
      return false;
    }
  }

  Future<Task?> toggleTaskStatus(String taskId) async {
    final currentTasks = state.value ?? [];
    final task = currentTasks.firstWhere((t) => t.id == taskId);

    final newStatus = task.status == TaskStatus.completed
        ? TaskStatus.pending
        : TaskStatus.completed;

    return await updateTask(taskId, status: newStatus);
  }

  void setFilter(TaskFilter filter) {
    _currentFilter = filter;
    final currentTasks = _localStorage.getAllTasks()
        .map((taskData) => Task.fromJson(taskData))
        .toList();
    final filteredTasks = _applyFiltersAndSorting(currentTasks);
    state = AsyncValue.data(filteredTasks);
  }

  void setSort(TaskSort sort) {
    _currentSort = sort;
    final currentTasks = _localStorage.getAllTasks()
        .map((taskData) => Task.fromJson(taskData))
        .toList();
    final sortedTasks = _applyFiltersAndSorting(currentTasks);
    state = AsyncValue.data(sortedTasks);
  }

  void clearFilter() {
    _currentFilter = TaskFilter();
    loadTasks();
  }

  TaskFilter get currentFilter => _currentFilter;
  TaskSort get currentSort => _currentSort;
}

class SubtaskNotifier extends StateNotifier<AsyncValue<List<Subtask>>> {
  SubtaskNotifier(this.taskId) : super(const AsyncValue.loading()) {
    _initialize();
  }

  final String taskId;
  final ApiClient _apiClient = ApiClient.instance;
  final LocalStorage _localStorage = LocalStorage.instance;

  Future<void> _initialize() async {
    await _localStorage.initialize();
    await loadSubtasks();
  }

  Future<void> loadSubtasks({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh) {
        // Load from local storage first
        final localSubtasks = _localStorage.getSubtasksForTask(taskId)
            .map((subtaskData) => Subtask.fromJson(subtaskData))
            .toList();

        if (localSubtasks.isNotEmpty) {
          state = AsyncValue.data(localSubtasks);
        }
      }

      // Fetch from server
      final response = await _apiClient.get('/tasks/$taskId/subtasks');

      if (response.isSuccess) {
        final subtasks = (response.data['subtasks'] as List)
            .map((subtaskData) => Subtask.fromJson(subtaskData))
            .toList();

        // Save to local storage
        final subtasksData = subtasks.map((subtask) => subtask.toJson()).toList();
        await _localStorage.saveSubtasks(subtasksData);

        state = AsyncValue.data(subtasks);
      } else {
        throw Exception(response.error ?? 'Failed to load subtasks');
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<Subtask?> createSubtask({
    required String title,
    int? order,
  }) async {
    try {
      final response = await _apiClient.post('/tasks/$taskId/subtasks', data: {
        'title': title,
        'order': order ?? (state.value?.length ?? 0),
      });

      if (response.isSuccess) {
        final subtask = Subtask.fromJson(response.data);

        // Save to local storage
        await _localStorage.saveSubtask(subtask.id, subtask.toJson());

        // Update state
        await loadSubtasks();

        return subtask;
      } else {
        throw Exception(response.error ?? 'Failed to create subtask');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Subtask?> updateSubtask(String subtaskId, {
    String? title,
    bool? isCompleted,
    int? order,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (title != null) updateData['title'] = title;
      if (isCompleted != null) updateData['is_completed'] = isCompleted;
      if (order != null) updateData['order'] = order;

      final response = await _apiClient.put('/tasks/$taskId/subtasks/$subtaskId', data: updateData);

      if (response.isSuccess) {
        final subtask = Subtask.fromJson(response.data);

        // Save to local storage
        await _localStorage.saveSubtask(subtask.id, subtask.toJson());

        // Update state
        await loadSubtasks();

        return subtask;
      } else {
        throw Exception(response.error ?? 'Failed to update subtask');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deleteSubtask(String subtaskId) async {
    try {
      final response = await _apiClient.delete('/tasks/$taskId/subtasks/$subtaskId');

      if (response.isSuccess) {
        // Remove from local storage
        await _localStorage.deleteSubtask(subtaskId);

        // Update state
        await loadSubtasks();

        return true;
      } else {
        throw Exception(response.error ?? 'Failed to delete subtask');
      }
    } catch (e) {
      return false;
    }
  }

  Future<Subtask?> toggleSubtaskComplete(String subtaskId) async {
    final currentSubtasks = state.value ?? [];
    final subtask = currentSubtasks.firstWhere((s) => s.id == subtaskId);

    return await updateSubtask(subtaskId, isCompleted: !subtask.isCompleted);
  }
}

// Provider definitions
final taskProvider = StateNotifierProvider<TaskNotifier, AsyncValue<List<Task>>>((ref) {
  return TaskNotifier();
});

final subtaskProvider = StateNotifierProvider.family<SubtaskNotifier, AsyncValue<List<Subtask>>, String>((ref, taskId) {
  return SubtaskNotifier(taskId);
});

final taskFilterProvider = StateProvider<TaskFilter>((ref) => TaskFilter());

final taskSortProvider = StateProvider<TaskSort>((ref) => TaskSort());

final filteredTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(taskProvider).value ?? [];
  final filter = ref.watch(taskFilterProvider);

  return tasks.where((task) {
    if (filter.status != null && task.status != filter.status) return false;
    if (filter.priority != null && task.priority != filter.priority) return false;
    if (filter.tags != null && filter.tags!.isNotEmpty) {
      if (!filter.tags!.any((tag) => task.tags.contains(tag))) return false;
    }
    if (filter.search != null && filter.search!.isNotEmpty) {
      final searchLower = filter.search!.toLowerCase();
      if (!task.title.toLowerCase().contains(searchLower) &&
          (task.description == null || !task.description!.toLowerCase().contains(searchLower))) {
        return false;
      }
    }
    return true;
  }).toList();
});

final taskByIdProvider = Provider.family<Task?, String>((ref, taskId) {
  final tasks = ref.watch(taskProvider).value ?? [];
  try {
    return tasks.firstWhere((task) => task.id == taskId);
  } catch (e) {
    return null;
  }
});

final todayTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(taskProvider).value ?? [];
  final today = DateTime.now();

  return tasks.where((task) =>
    task.isDueToday ||
    (task.status == TaskStatus.inProgress) ||
    (task.createdAt.year == today.year &&
     task.createdAt.month == today.month &&
     task.createdAt.day == today.day)
  ).toList();
});

final overdueTa
sProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(taskProvider).value ?? [];
  return tasks.where((task) => task.isOverdue).toList();
});

final upcomingTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(taskProvider).value ?? [];
  return tasks.where((task) => task.isDueSoon).toList();
});

final completedTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(taskProvider).value ?? [];
  return tasks.where((task) => task.isCompleted).toList();
});

final taskStatsProvider = Provider<Map<String, int>>((ref) {
  final tasks = ref.watch(taskProvider).value ?? [];

  return {
    'total': tasks.length,
    'completed': tasks.where((task) => task.isCompleted).length,
    'pending': tasks.where((task) => task.status == TaskStatus.pending).length,
    'in_progress': tasks.where((task) => task.status == TaskStatus.inProgress).length,
    'overdue': tasks.where((task) => task.isOverdue).length,
    'due_today': tasks.where((task) => task.isDueToday).length,
    'due_soon': tasks.where((task) => task.isDueSoon).length,
  };
});