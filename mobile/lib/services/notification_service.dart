import 'package:flutter/foundation.dart' show kIsWeb;
import 'notification_service_stub.dart'
    if (dart.library.html) 'notification_service_web.dart'
    if (dart.library.io) 'notification_service_native.dart';

/// Cross-platform notification service
abstract class NotificationService {
  factory NotificationService() => getNotificationService();

  Future<void> initialize();
  Future<void> showNotification({
    required String title,
    String? body,
    String? icon,
    int? duration,
  });
  Future<void> showPomodoroCompleted({String? taskTitle});
  Future<void> showBreakStarted({required int breakMinutes});
  Future<void> showBreakEnded();
  Future<void> showBreakCompleted({required String breakType});
  Future<bool> requestPermission();
  bool get hasPermission;
  bool get isInitialized;
}
