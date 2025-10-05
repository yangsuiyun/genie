import 'dart:html' as html;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _permissionGranted = false;
  bool _initialized = false;

  // 初始化通知服务
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 检查浏览器是否支持通知
      if (!_isNotificationSupported()) {
        print('Browser does not support notifications');
        return;
      }

      // 检查当前权限状态
      final permission = html.Notification.permission;
      if (permission == 'granted') {
        _permissionGranted = true;
      } else if (permission == 'default') {
        // 请求权限
        await _requestPermission();
      } else {
        print('Notification permission denied');
      }

      _initialized = true;
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  // 检查浏览器是否支持通知
  bool _isNotificationSupported() {
    try {
      return html.Notification.supported;
    } catch (e) {
      return false;
    }
  }

  // 请求通知权限
  Future<void> _requestPermission() async {
    try {
      final permission = await html.Notification.requestPermission();
      _permissionGranted = permission == 'granted';
      if (_permissionGranted) {
        print('Notification permission granted');
      } else {
        print('Notification permission denied by user');
      }
    } catch (e) {
      print('Error requesting notification permission: $e');
    }
  }

  // 发送通知
  Future<void> showNotification({
    required String title,
    String? body,
    String? icon,
    int? duration,
  }) async {
    if (!_permissionGranted) {
      print('Notification permission not granted');
      return;
    }

    try {
      final notification = html.Notification(
        title,
        body: body,
        icon: icon ?? '/favicon.png', // 使用应用图标
      );

      // 可选：设置点击事件
      notification.onClick.listen((event) {
        print('Notification clicked');
        // 聚焦到窗口
        html.window.focus();
        notification.close();
      });

      // 可选：自动关闭通知
      if (duration != null) {
        Future.delayed(Duration(milliseconds: duration), () {
          notification.close();
        });
      }
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  // 发送番茄钟完成通知
  Future<void> showPomodoroCompleted({String? taskTitle}) async {
    final title = '🍅 番茄钟完成！';
    final body = taskTitle != null
        ? '任务"$taskTitle"的番茄钟已完成，是时候休息一下了！'
        : '番茄钟已完成，是时候休息一下了！';

    await showNotification(
      title: title,
      body: body,
      duration: 5000, // 5秒后自动关闭
    );
  }

  // 发送休息时间开始通知
  Future<void> showBreakStarted({required int breakMinutes}) async {
    await showNotification(
      title: '☕ 休息时间开始',
      body: '享受$breakMinutes分钟的休息时间吧！',
      duration: 3000,
    );
  }

  // 发送休息时间结束通知
  Future<void> showBreakEnded() async {
    await showNotification(
      title: '⏰ 休息时间结束',
      body: '休息结束，准备开始下一个番茄钟吧！',
      duration: 5000,
    );
  }

  // 检查权限状态
  bool get hasPermission => _permissionGranted;
  bool get isInitialized => _initialized;

  // 手动请求权限（供用户在设置中使用）
  Future<bool> requestPermission() async {
    if (!_isNotificationSupported()) {
      return false;
    }

    await _requestPermission();
    return _permissionGranted;
  }
}