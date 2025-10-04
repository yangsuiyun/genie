import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'api_client.dart';
import 'local_storage.dart';

enum NotificationType {
  pomodoroComplete,
  pomodoroBreakComplete,
  taskReminder,
  taskDue,
  taskOverdue,
  dailyReport,
  weeklyReport,
  sync,
}

enum NotificationPriority { low, normal, high, max }

class PushNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic>? data;
  final DateTime scheduledTime;
  final NotificationPriority priority;

  PushNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    required this.scheduledTime,
    this.priority = NotificationPriority.normal,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type.toString().split('.').last,
        'data': data,
        'scheduled_time': scheduledTime.toIso8601String(),
        'priority': priority.toString().split('.').last,
      };

  factory PushNotification.fromJson(Map<String, dynamic> json) => PushNotification(
        id: json['id'],
        title: json['title'],
        body: json['body'],
        type: NotificationType.values.firstWhere(
          (e) => e.toString().split('.').last == json['type'],
          orElse: () => NotificationType.taskReminder,
        ),
        data: json['data'],
        scheduledTime: DateTime.parse(json['scheduled_time']),
        priority: NotificationPriority.values.firstWhere(
          (e) => e.toString().split('.').last == json['priority'],
          orElse: () => NotificationPriority.normal,
        ),
      );
}

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService._();

  NotificationService._();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final ApiClient _apiClient = ApiClient.instance;
  final LocalStorage _localStorage = LocalStorage.instance;

  final StreamController<PushNotification> _notificationController = StreamController<PushNotification>.broadcast();
  Stream<PushNotification> get notificationStream => _notificationController.stream;

  String? _fcmToken;
  bool _isInitialized = false;

  // Notification channels
  static const String _pomodoroChannelId = 'pomodoro_notifications';
  static const String _reminderChannelId = 'reminder_notifications';
  static const String _reportsChannelId = 'reports_notifications';
  static const String _syncChannelId = 'sync_notifications';

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _localStorage.initialize();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Initialize Firebase messaging
    await _initializeFirebaseMessaging();

    // Request permissions
    await _requestPermissions();

    // Setup listeners
    _setupMessageListeners();

    _isInitialized = true;
  }

  Future<void> _initializeLocalNotifications() async {
    const androidInitialization = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInitialization = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initializationSettings = InitializationSettings(
      android: androidInitialization,
      iOS: iosInitialization,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );

    // Create notification channels for Android
    if (!kIsWeb) {
      await _createNotificationChannels();
    }
  }

  Future<void> _createNotificationChannels() async {
    const pomodoroChannel = AndroidNotificationChannel(
      _pomodoroChannelId,
      'Pomodoro Timer',
      description: 'Notifications for pomodoro timer events',
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('pomodoro_complete'),
    );

    const reminderChannel = AndroidNotificationChannel(
      _reminderChannelId,
      'Task Reminders',
      description: 'Notifications for task reminders and due dates',
      importance: Importance.high,
    );

    const reportsChannel = AndroidNotificationChannel(
      _reportsChannelId,
      'Reports',
      description: 'Daily and weekly productivity reports',
      importance: Importance.defaultImportance,
    );

    const syncChannel = AndroidNotificationChannel(
      _syncChannelId,
      'Sync Status',
      description: 'Data synchronization status updates',
      importance: Importance.low,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(pomodoroChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(reminderChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(reportsChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(syncChannel);
  }

  Future<void> _initializeFirebaseMessaging() async {
    // Get FCM token
    _fcmToken = await _firebaseMessaging.getToken();
    if (_fcmToken != null) {
      await _localStorage.saveSetting('fcm_token', _fcmToken);
      await _registerTokenWithServer();
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((String token) async {
      _fcmToken = token;
      await _localStorage.saveSetting('fcm_token', token);
      await _registerTokenWithServer();
    });
  }

  Future<void> _registerTokenWithServer() async {
    if (_fcmToken == null) return;

    try {
      await _apiClient.post('/notifications/register', data: {
        'fcm_token': _fcmToken,
        'platform': Theme.of(navigatorKey.currentContext!).platform.name,
        'app_version': await _getAppVersion(),
      });
    } catch (e) {
      debugPrint('Failed to register FCM token: $e');
    }
  }

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<String> _getAppVersion() async {
    // Implementation would get version from package_info_plus
    return '1.0.0';
  }

  Future<void> _requestPermissions() async {
    // Request notification permissions
    final notificationStatus = await Permission.notification.request();

    // Request exact alarm permission for Android 12+
    if (Theme.of(navigatorKey.currentContext!).platform == TargetPlatform.android) {
      await Permission.scheduleExactAlarm.request();
    }

    // Request Firebase messaging permissions
    final messagingSettings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      carPlay: true,
      criticalAlert: false,
      provisional: false,
      announcement: false,
    );

    await _localStorage.saveSetting('notification_permissions_granted',
        notificationStatus == PermissionStatus.granted &&
        messagingSettings.authorizationStatus == AuthorizationStatus.authorized);
  }

  void _setupMessageListeners() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background message taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageTap);

    // Handle app launched from terminated state
    _firebaseMessaging.getInitialMessage().then((message) {
      if (message != null) {
        _handleBackgroundMessageTap(message);
      }
    });
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = _parseRemoteMessage(message);
    if (notification != null) {
      // Show local notification for foreground messages
      await _showLocalNotification(notification);
      _notificationController.add(notification);
    }
  }

  Future<void> _handleBackgroundMessageTap(RemoteMessage message) async {
    final notification = _parseRemoteMessage(message);
    if (notification != null) {
      _notificationController.add(notification);
      await _handleNotificationAction(notification);
    }
  }

  void _onLocalNotificationTapped(NotificationResponse response) async {
    final payload = response.payload;
    if (payload != null) {
      try {
        final data = jsonDecode(payload);
        final notification = PushNotification.fromJson(data);
        _notificationController.add(notification);
        await _handleNotificationAction(notification);
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  PushNotification? _parseRemoteMessage(RemoteMessage message) {
    try {
      final data = message.data;
      final typeStr = data['type'] ?? 'task_reminder';

      return PushNotification(
        id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: message.notification?.title ?? data['title'] ?? '',
        body: message.notification?.body ?? data['body'] ?? '',
        type: NotificationType.values.firstWhere(
          (e) => e.toString().split('.').last == typeStr,
          orElse: () => NotificationType.taskReminder,
        ),
        data: data,
        scheduledTime: DateTime.now(),
        priority: _parsePriority(data['priority']),
      );
    } catch (e) {
      debugPrint('Error parsing remote message: $e');
      return null;
    }
  }

  NotificationPriority _parsePriority(String? priorityStr) {
    return NotificationPriority.values.firstWhere(
      (e) => e.toString().split('.').last == priorityStr,
      orElse: () => NotificationPriority.normal,
    );
  }

  Future<void> _handleNotificationAction(PushNotification notification) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    switch (notification.type) {
      case NotificationType.pomodoroComplete:
      case NotificationType.pomodoroBreakComplete:
        // Navigate to pomodoro screen
        Navigator.of(context).pushNamed('/timer');
        break;

      case NotificationType.taskReminder:
      case NotificationType.taskDue:
      case NotificationType.taskOverdue:
        // Navigate to task detail
        final taskId = notification.data?['task_id'];
        if (taskId != null) {
          Navigator.of(context).pushNamed('/task/$taskId');
        }
        break;

      case NotificationType.dailyReport:
      case NotificationType.weeklyReport:
        // Navigate to reports screen
        Navigator.of(context).pushNamed('/reports');
        break;

      case NotificationType.sync:
        // Handle sync notifications
        break;
    }
  }

  // Local Notifications
  Future<void> scheduleLocalNotification(PushNotification notification) async {
    await _showLocalNotification(notification, scheduledDate: notification.scheduledTime);
  }

  Future<void> _showLocalNotification(
    PushNotification notification, {
    DateTime? scheduledDate,
  }) async {
    final channelId = _getChannelIdForType(notification.type);
    final importance = _getImportanceForPriority(notification.priority);
    final priority = _getPriorityForPriority(notification.priority);

    final androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelNameForId(channelId),
      channelDescription: _getChannelDescriptionForId(channelId),
      importance: importance,
      priority: priority,
      enableVibration: notification.priority != NotificationPriority.low,
      playSound: notification.priority != NotificationPriority.low,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id = notification.id.hashCode;
    final payload = jsonEncode(notification.toJson());

    if (scheduledDate != null && scheduledDate.isAfter(DateTime.now())) {
      await _localNotifications.zonedSchedule(
        id,
        notification.title,
        notification.body,
        _convertToTZDateTime(scheduledDate),
        details,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } else {
      await _localNotifications.show(
        id,
        notification.title,
        notification.body,
        details,
        payload: payload,
      );
    }
  }

  TZDateTime _convertToTZDateTime(DateTime dateTime) {
    // Implementation would use timezone package
    return TZDateTime.from(dateTime, getLocation('UTC'));
  }

  // Mock implementation for timezone conversion
  TZDateTime getLocation(String timezone) {
    // This is a placeholder - real implementation would use timezone package
    return TZDateTime.from(DateTime.now(), getLocation('UTC'));
  }

  String _getChannelIdForType(NotificationType type) {
    switch (type) {
      case NotificationType.pomodoroComplete:
      case NotificationType.pomodoroBreakComplete:
        return _pomodoroChannelId;
      case NotificationType.taskReminder:
      case NotificationType.taskDue:
      case NotificationType.taskOverdue:
        return _reminderChannelId;
      case NotificationType.dailyReport:
      case NotificationType.weeklyReport:
        return _reportsChannelId;
      case NotificationType.sync:
        return _syncChannelId;
    }
  }

  String _getChannelNameForId(String channelId) {
    switch (channelId) {
      case _pomodoroChannelId:
        return 'Pomodoro Timer';
      case _reminderChannelId:
        return 'Task Reminders';
      case _reportsChannelId:
        return 'Reports';
      case _syncChannelId:
        return 'Sync Status';
      default:
        return 'General';
    }
  }

  String _getChannelDescriptionForId(String channelId) {
    switch (channelId) {
      case _pomodoroChannelId:
        return 'Notifications for pomodoro timer events';
      case _reminderChannelId:
        return 'Notifications for task reminders and due dates';
      case _reportsChannelId:
        return 'Daily and weekly productivity reports';
      case _syncChannelId:
        return 'Data synchronization status updates';
      default:
        return 'General notifications';
    }
  }

  Importance _getImportanceForPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Importance.low;
      case NotificationPriority.normal:
        return Importance.defaultImportance;
      case NotificationPriority.high:
        return Importance.high;
      case NotificationPriority.max:
        return Importance.max;
    }
  }

  Priority _getPriorityForPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Priority.low;
      case NotificationPriority.normal:
        return Priority.defaultPriority;
      case NotificationPriority.high:
        return Priority.high;
      case NotificationPriority.max:
        return Priority.max;
    }
  }

  // Pomodoro Notifications
  Future<void> schedulePomodoroNotification({
    required String sessionId,
    required String taskTitle,
    required Duration sessionDuration,
    required bool isBreak,
  }) async {
    final scheduledTime = DateTime.now().add(sessionDuration);
    final type = isBreak ? NotificationType.pomodoroBreakComplete : NotificationType.pomodoroComplete;

    final notification = PushNotification(
      id: 'pomodoro_$sessionId',
      title: isBreak ? 'Break Time Complete!' : 'Pomodoro Complete!',
      body: isBreak
          ? 'Ready to start another pomodoro session?'
          : 'Great work on "$taskTitle"! Time for a break.',
      type: type,
      data: {
        'session_id': sessionId,
        'task_title': taskTitle,
        'is_break': isBreak,
      },
      scheduledTime: scheduledTime,
      priority: NotificationPriority.high,
    );

    await scheduleLocalNotification(notification);
  }

  Future<void> cancelPomodoroNotification(String sessionId) async {
    final notificationId = 'pomodoro_$sessionId'.hashCode;
    await _localNotifications.cancel(notificationId);
  }

  // Task Reminder Notifications
  Future<void> scheduleTaskReminder({
    required String taskId,
    required String taskTitle,
    required DateTime reminderTime,
    String? customMessage,
  }) async {
    final notification = PushNotification(
      id: 'reminder_$taskId',
      title: 'Task Reminder',
      body: customMessage ?? 'Don\'t forget: $taskTitle',
      type: NotificationType.taskReminder,
      data: {
        'task_id': taskId,
        'task_title': taskTitle,
      },
      scheduledTime: reminderTime,
      priority: NotificationPriority.normal,
    );

    await scheduleLocalNotification(notification);
  }

  Future<void> scheduleTaskDueNotification({
    required String taskId,
    required String taskTitle,
    required DateTime dueDate,
  }) async {
    final notification = PushNotification(
      id: 'due_$taskId',
      title: 'Task Due Soon',
      body: '"$taskTitle" is due today',
      type: NotificationType.taskDue,
      data: {
        'task_id': taskId,
        'task_title': taskTitle,
        'due_date': dueDate.toIso8601String(),
      },
      scheduledTime: dueDate.subtract(const Duration(hours: 1)),
      priority: NotificationPriority.high,
    );

    await scheduleLocalNotification(notification);
  }

  Future<void> cancelTaskNotifications(String taskId) async {
    final reminderNotificationId = 'reminder_$taskId'.hashCode;
    final dueNotificationId = 'due_$taskId'.hashCode;

    await _localNotifications.cancel(reminderNotificationId);
    await _localNotifications.cancel(dueNotificationId);
  }

  // Report Notifications
  Future<void> scheduleDailyReportNotification() async {
    final now = DateTime.now();
    final scheduledTime = DateTime(now.year, now.month, now.day, 20, 0); // 8 PM

    if (scheduledTime.isBefore(now)) {
      return; // Don't schedule for today if it's already past 8 PM
    }

    final notification = PushNotification(
      id: 'daily_report_${now.day}',
      title: 'Daily Productivity Report',
      body: 'Check out your productivity stats for today!',
      type: NotificationType.dailyReport,
      data: {
        'report_date': now.toIso8601String(),
      },
      scheduledTime: scheduledTime,
      priority: NotificationPriority.normal,
    );

    await scheduleLocalNotification(notification);
  }

  Future<void> scheduleWeeklyReportNotification() async {
    final now = DateTime.now();
    final daysUntilSunday = 7 - now.weekday;
    final nextSunday = now.add(Duration(days: daysUntilSunday));
    final scheduledTime = DateTime(nextSunday.year, nextSunday.month, nextSunday.day, 10, 0); // 10 AM Sunday

    final notification = PushNotification(
      id: 'weekly_report_${nextSunday.day}',
      title: 'Weekly Productivity Report',
      body: 'Your week in review - see how productive you\'ve been!',
      type: NotificationType.weeklyReport,
      data: {
        'week_start': now.toIso8601String(),
        'week_end': nextSunday.toIso8601String(),
      },
      scheduledTime: scheduledTime,
      priority: NotificationPriority.normal,
    );

    await scheduleLocalNotification(notification);
  }

  // Notification Management
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _localNotifications.pendingNotificationRequests();
  }

  Future<void> cancelNotification(int notificationId) async {
    await _localNotifications.cancel(notificationId);
  }

  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  // Settings Management
  Future<void> updateNotificationSettings({
    bool? enablePomodoroNotifications,
    bool? enableTaskReminders,
    bool? enableReports,
    bool? enableSound,
    bool? enableVibration,
    String? dailyReportTime,
    String? weeklyReportDay,
  }) async {
    final settings = <String, dynamic>{};

    if (enablePomodoroNotifications != null) {
      settings['enable_pomodoro_notifications'] = enablePomodoroNotifications;
    }
    if (enableTaskReminders != null) {
      settings['enable_task_reminders'] = enableTaskReminders;
    }
    if (enableReports != null) {
      settings['enable_reports'] = enableReports;
    }
    if (enableSound != null) {
      settings['enable_notification_sound'] = enableSound;
    }
    if (enableVibration != null) {
      settings['enable_notification_vibration'] = enableVibration;
    }
    if (dailyReportTime != null) {
      settings['daily_report_time'] = dailyReportTime;
    }
    if (weeklyReportDay != null) {
      settings['weekly_report_day'] = weeklyReportDay;
    }

    await _localStorage.saveSettings(settings);
  }

  Map<String, dynamic> getNotificationSettings() {
    return {
      'enable_pomodoro_notifications': _localStorage.getSetting('enable_pomodoro_notifications', true),
      'enable_task_reminders': _localStorage.getSetting('enable_task_reminders', true),
      'enable_reports': _localStorage.getSetting('enable_reports', true),
      'enable_notification_sound': _localStorage.getSetting('enable_notification_sound', true),
      'enable_notification_vibration': _localStorage.getSetting('enable_notification_vibration', true),
      'daily_report_time': _localStorage.getSetting('daily_report_time', '20:00'),
      'weekly_report_day': _localStorage.getSetting('weekly_report_day', 'sunday'),
    };
  }

  // Test Notification
  Future<void> sendTestNotification() async {
    final notification = PushNotification(
      id: 'test_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Test Notification',
      body: 'This is a test notification to verify your settings.',
      type: NotificationType.taskReminder,
      data: {'test': true},
      scheduledTime: DateTime.now(),
      priority: NotificationPriority.normal,
    );

    await _showLocalNotification(notification);
  }

  void dispose() {
    _notificationController.close();
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages
  debugPrint('Handling a background message: ${message.messageId}');
}

// Placeholder for timezone import
class TZDateTime {
  final DateTime dateTime;
  TZDateTime(this.dateTime);

  static TZDateTime from(DateTime dateTime, location) {
    return TZDateTime(dateTime);
  }
}