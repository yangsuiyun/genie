import 'notification_service.dart';

NotificationService getNotificationService() => NativeNotificationService._instance;

class NativeNotificationService implements NotificationService {
  static final NativeNotificationService _instance = NativeNotificationService._internal();
  NativeNotificationService._internal();

  bool _initialized = false;

  @override
  Future<void> initialize() async {
    // TODO: Implement native notifications using flutter_local_notifications
    _initialized = true;
  }

  @override
  Future<void> showNotification({
    required String title,
    String? body,
    String? icon,
    int? duration,
  }) async {
    // TODO: Implement native notification
    print('Native notification: $title - $body');
  }

  @override
  Future<void> showPomodoroCompleted({String? taskTitle}) async {
    final title = '🍅 番茄钟完成！';
    final body = taskTitle != null
        ? '任务"$taskTitle"的番茄钟已完成，是时候休息一下了！'
        : '番茄钟已完成，是时候休息一下了！';
    await showNotification(title: title, body: body);
  }

  @override
  Future<void> showBreakStarted({required int breakMinutes}) async {
    await showNotification(
      title: '☕ 休息时间开始',
      body: '享受$breakMinutes分钟的休息时间吧！',
    );
  }

  @override
  Future<void> showBreakEnded() async {
    await showNotification(
      title: '⏰ 休息时间结束',
      body: '休息结束，准备开始下一个番茄钟吧！',
    );
  }

  @override
  Future<void> showBreakCompleted({required String breakType}) async {
    await showNotification(
      title: '✅ 休息完成',
      body: '$breakType已结束！',
    );
  }

  @override
  Future<bool> requestPermission() async {
    // Native platforms don't need permission request
    return true;
  }

  @override
  bool get hasPermission => true;

  @override
  bool get isInitialized => _initialized;
}
