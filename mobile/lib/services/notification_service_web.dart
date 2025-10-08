import 'dart:html' as html;
import 'notification_service.dart';

NotificationService getNotificationService() => WebNotificationService._instance;

class WebNotificationService implements NotificationService {
  static final WebNotificationService _instance = WebNotificationService._internal();
  WebNotificationService._internal();

  bool _permissionGranted = false;
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (!_isNotificationSupported()) {
        print('Browser does not support notifications');
        return;
      }

      final permission = html.Notification.permission;
      if (permission == 'granted') {
        _permissionGranted = true;
      } else if (permission == 'default') {
        await _requestPermission();
      }

      _initialized = true;
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  bool _isNotificationSupported() {
    try {
      return html.Notification.supported;
    } catch (e) {
      return false;
    }
  }

  Future<void> _requestPermission() async {
    try {
      final permission = await html.Notification.requestPermission();
      _permissionGranted = permission == 'granted';
    } catch (e) {
      print('Error requesting notification permission: $e');
    }
  }

  @override
  Future<void> showNotification({
    required String title,
    String? body,
    String? icon,
    int? duration,
  }) async {
    if (!_permissionGranted) return;

    try {
      final notification = html.Notification(
        title,
        body: body,
        icon: icon ?? '/favicon.png',
      );

      notification.onClick.listen((event) {
        html.window.focus();
        notification.close();
      });

      if (duration != null) {
        Future.delayed(Duration(milliseconds: duration), () {
          notification.close();
        });
      }
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  @override
  Future<void> showPomodoroCompleted({String? taskTitle}) async {
    final title = '🍅 番茄钟完成！';
    final body = taskTitle != null
        ? '任务"$taskTitle"的番茄钟已完成，是时候休息一下了！'
        : '番茄钟已完成，是时候休息一下了！';

    await showNotification(title: title, body: body, duration: 5000);
  }

  @override
  Future<void> showBreakStarted({required int breakMinutes}) async {
    await showNotification(
      title: '☕ 休息时间开始',
      body: '享受$breakMinutes分钟的休息时间吧！',
      duration: 3000,
    );
  }

  @override
  Future<void> showBreakEnded() async {
    await showNotification(
      title: '⏰ 休息时间结束',
      body: '休息结束，准备开始下一个番茄钟吧！',
      duration: 5000,
    );
  }

  @override
  Future<void> showBreakCompleted({required String breakType}) async {
    await showNotification(
      title: '✅ 休息完成',
      body: '$breakType已结束！',
      duration: 3000,
    );
  }

  @override
  Future<bool> requestPermission() async {
    if (!_isNotificationSupported()) return false;
    await _requestPermission();
    return _permissionGranted;
  }

  @override
  bool get hasPermission => _permissionGranted;

  @override
  bool get isInitialized => _initialized;
}
