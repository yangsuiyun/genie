// Tasks provider
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../services/task_service.dart';

// Task service provider
final taskServiceProvider = Provider<TaskService>((ref) {
  return TaskService();
});

// Tasks provider
final tasksProvider = FutureProvider<List<Task>>((ref) async {
  final taskService = ref.read(taskServiceProvider);
  return taskService.tasks;
});

// Selected task provider
final selectedTaskProvider = StateProvider<Task?>((ref) => null);

// Task filter provider
final taskFilterProvider = StateProvider<TaskFilter>((ref) => TaskFilter());

// Filtered tasks provider
final filteredTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(tasksProvider).value ?? [];
  final filter = ref.watch(taskFilterProvider);
  
  return tasks.where((task) {
    if (filter.status != null && task.status != filter.status) return false;
    if (filter.priority != null && task.priority != filter.priority) return false;
    if (filter.search != null && filter.search!.isNotEmpty) {
      final searchLower = filter.search!.toLowerCase();
      if (!task.title.toLowerCase().contains(searchLower)) return false;
    }
    return true;
  }).toList();
});

// Task filter class
class TaskFilter {
  final TaskStatus? status;
  final TaskPriority? priority;
  final String? search;

  TaskFilter({
    this.status,
    this.priority,
    this.search,
  });

  TaskFilter copyWith({
    TaskStatus? status,
    TaskPriority? priority,
    String? search,
  }) {
    return TaskFilter(
      status: status ?? this.status,
      priority: priority ?? this.priority,
      search: search ?? this.search,
    );
  }
}
