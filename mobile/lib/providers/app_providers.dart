import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../services/task_service.dart';
import '../services/session_service.dart';
import '../services/notification_service.dart';
import '../services/sync_service.dart';

// TaskService Provider
final taskServiceProvider = Provider<TaskService>((ref) {
  return TaskService();
});

// SessionService Provider
final sessionServiceProvider = Provider<SessionService>((ref) {
  return SessionService();
});

// NotificationService Provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// SyncService Provider
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService();
});

// 任务列表Provider
final taskListProvider = FutureProvider<List<Task>>((ref) async {
  final taskService = ref.watch(taskServiceProvider);
  return taskService.getAllTasks();
});

// 当前任务Provider
final currentTaskProvider = StateProvider<Task?>((ref) => null);

// 选中的过滤器Provider
final selectedFilterProvider = StateProvider<TaskTimeFilter>((ref) => TaskTimeFilter.today);

// 侧边栏显示状态Provider
final sidebarVisibleProvider = StateProvider<bool>((ref) => true);

// 全屏模式状态Provider
final fullscreenModeProvider = StateProvider<bool>((ref) => false);

