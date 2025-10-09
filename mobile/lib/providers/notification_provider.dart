import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import '../models/index.dart';

class NotificationNotifier extends StateNotifier<List<PushNotification>> {
  NotificationNotifier() : super([]) {
    _initialize();
  }

  final NotificationService _notificationService = NotificationService();

  Future<void> _initialize() async {
    await _notificationService.initialize();

    // Listen to incoming notifications
    // _notificationService.notificationStream.listen((notification) {
    //   state = [notification, ...state];
    // });
  }

  Future<void> scheduleTaskReminder({
    required String taskId,
    required String taskTitle,
    required DateTime reminderTime,
    String? customMessage,
  }) async {
    // await _notificationService.scheduleTaskReminder(
    //   taskId: taskId,
    //   taskTitle: taskTitle,
    //   reminderTime: reminderTime,
    //   customMessage: customMessage,
    // );
  }

  Future<void> scheduleTaskDueNotification({
    required String taskId,
    required String taskTitle,
    required DateTime dueDate,
  }) async {
    // await _notificationService.scheduleTaskDueNotification(
    //   taskId: taskId,
    //   taskTitle: taskTitle,
    //   dueDate: dueDate,
    // );
  }

  Future<void> schedulePomodoroNotification({
    required String sessionId,
    required String taskTitle,
    required Duration sessionDuration,
    required bool isBreak,
  }) async {
    // await _notificationService.schedulePomodoroNotification(
    //   sessionId: sessionId,
    //   taskTitle: taskTitle,
    //   sessionDuration: sessionDuration,
    //   isBreak: isBreak,
    // );
  }

  Future<void> cancelTaskNotifications(String taskId) async {
    // await _notificationService.cancelTaskNotifications(taskId);
  }

  Future<void> cancelPomodoroNotification(String sessionId) async {
    // await _notificationService.cancelPomodoroNotification(sessionId);
  }

  Future<void> scheduleDailyReportNotification() async {
    // await _notificationService.scheduleDailyReportNotification();
  }

  Future<void> scheduleWeeklyReportNotification() async {
    // await _notificationService.scheduleWeeklyReportNotification();
  }

  Future<void> updateNotificationSettings({
    bool? enablePomodoroNotifications,
    bool? enableTaskReminders,
    bool? enableReports,
    bool? enableSound,
    bool? enableVibration,
    String? dailyReportTime,
    String? weeklyReportDay,
  }) async {
    await _notificationService.updateNotificationSettings(
      enablePomodoroNotifications: enablePomodoroNotifications,
      enableTaskReminders: enableTaskReminders,
      enableReports: enableReports,
      enableSound: enableSound,
      enableVibration: enableVibration,
      dailyReportTime: dailyReportTime,
      weeklyReportDay: weeklyReportDay,
    );
  }

  Map<String, dynamic> getNotificationSettings() {
    return _notificationService.getNotificationSettings();
  }

  Future<void> sendTestNotification() async {
    await _notificationService.sendTestNotification();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notificationService.getPendingNotifications();
  }

  Future<void> cancelNotification(int notificationId) async {
    await _notificationService.cancelNotification(notificationId);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationService.cancelAllNotifications();
  }

  void markAsRead(String notificationId) {
    state = state.map((notification) {
      if (notification.id == notificationId) {
        // In a real implementation, you might want to add a 'read' property to PushNotification
        return notification;
      }
      return notification;
    }).toList();
  }

  void clearNotification(String notificationId) {
    state = state.where((notification) => notification.id != notificationId).toList();
  }

  void clearAllNotifications() {
    state = [];
  }
}

class NotificationSettingsNotifier extends StateNotifier<Map<String, dynamic>> {
  NotificationSettingsNotifier() : super({}) {
    _initialize();
  }

  final NotificationService _notificationService = NotificationService();

  Future<void> _initialize() async {
    await _notificationService.initialize();
    state = _notificationService.getNotificationSettings();
  }

  Future<void> updateSettings({
    bool? enablePomodoroNotifications,
    bool? enableTaskReminders,
    bool? enableReports,
    bool? enableSound,
    bool? enableVibration,
    String? dailyReportTime,
    String? weeklyReportDay,
  }) async {
    await _notificationService.updateNotificationSettings(
      enablePomodoroNotifications: enablePomodoroNotifications,
      enableTaskReminders: enableTaskReminders,
      enableReports: enableReports,
      enableSound: enableSound,
      enableVibration: enableVibration,
      dailyReportTime: dailyReportTime,
      weeklyReportDay: weeklyReportDay,
    );

    // Update state
    state = _notificationService.getNotificationSettings();
  }
}

// Provider definitions
final notificationProvider = StateNotifierProvider<NotificationNotifier, List<PushNotification>>((ref) {
  return NotificationNotifier();
});

final notificationSettingsProvider = StateNotifierProvider<NotificationSettingsNotifier, Map<String, dynamic>>((ref) {
  return NotificationSettingsNotifier();
});

final unreadNotificationsProvider = Provider<List<PushNotification>>((ref) {
  final notifications = ref.watch(notificationProvider);
  // In a real implementation, you would filter by read status
  return notifications;
});

final notificationCountProvider = Provider<int>((ref) {
  return ref.watch(unreadNotificationsProvider).length;
});

final hasUnreadNotificationsProvider = Provider<bool>((ref) {
  return ref.watch(notificationCountProvider) > 0;
});

final enablePomodoroNotificationsProvider = Provider<bool>((ref) {
  final settings = ref.watch(notificationSettingsProvider);
  return settings['enable_pomodoro_notifications'] ?? true;
});

final enableTaskRemindersProvider = Provider<bool>((ref) {
  final settings = ref.watch(notificationSettingsProvider);
  return settings['enable_task_reminders'] ?? true;
});

final enableReportsProvider = Provider<bool>((ref) {
  final settings = ref.watch(notificationSettingsProvider);
  return settings['enable_reports'] ?? true;
});

final enableNotificationSoundProvider = Provider<bool>((ref) {
  final settings = ref.watch(notificationSettingsProvider);
  return settings['enable_notification_sound'] ?? true;
});

final enableNotificationVibrationProvider = Provider<bool>((ref) {
  final settings = ref.watch(notificationSettingsProvider);
  return settings['enable_notification_vibration'] ?? true;
});

final pendingNotificationsProvider = FutureProvider<List<PendingNotificationRequest>>((ref) async {
  final notificationService = NotificationService.instance;
  return await notificationService.getPendingNotifications();
});