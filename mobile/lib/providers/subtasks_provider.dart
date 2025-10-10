// Subtasks provider
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../services/task_service.dart';

// Subtask service provider
final subtaskServiceProvider = Provider<SubtaskService>((ref) {
  return SubtaskService();
});

// Subtasks provider
final subtasksProvider = FutureProvider<List<Subtask>>((ref) async {
  final subtaskService = ref.read(subtaskServiceProvider);
  return subtaskService.subtasks;
});

// Selected subtask provider
final selectedSubtaskProvider = StateProvider<Subtask?>((ref) => null);

// Subtask filter provider
final subtaskFilterProvider = StateProvider<SubtaskFilter>((ref) => SubtaskFilter());

// Filtered subtasks provider
final filteredSubtasksProvider = Provider<List<Subtask>>((ref) {
  final subtasks = ref.watch(subtasksProvider).value ?? [];
  final filter = ref.watch(subtaskFilterProvider);
  
  return subtasks.where((subtask) {
    if (filter.status != null && subtask.status != filter.status) return false;
    if (filter.taskId != null && subtask.taskId != filter.taskId) return false;
    return true;
  }).toList();
});

// Subtask service class
class SubtaskService {
  List<Subtask> _subtasks = [];

  List<Subtask> get subtasks => _subtasks;

  void addSubtask(Subtask subtask) {
    _subtasks.add(subtask);
  }

  void updateSubtask(Subtask subtask) {
    final index = _subtasks.indexWhere((s) => s.id == subtask.id);
    if (index != -1) {
      _subtasks[index] = subtask;
    }
  }

  void deleteSubtask(String subtaskId) {
    _subtasks.removeWhere((s) => s.id == subtaskId);
  }
}

// Subtask filter class
class SubtaskFilter {
  final TaskStatus? status;
  final String? taskId;

  SubtaskFilter({
    this.status,
    this.taskId,
  });

  SubtaskFilter copyWith({
    TaskStatus? status,
    String? taskId,
  }) {
    return SubtaskFilter(
      status: status ?? this.status,
      taskId: taskId ?? this.taskId,
    );
  }
}
