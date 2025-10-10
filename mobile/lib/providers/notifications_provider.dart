import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationsProvider extends StateNotifier<bool> {
  NotificationsProvider() : super(false);

  Future<void> scheduleSessionEndNotification({
    required String sessionId,
    required DateTime endTime,
    required String title,
    required String body,
  }) async {
    // TODO: 实现通知调度
    print('📱 调度通知: $title - $body');
  }

  Future<void> cancelSessionNotification() async {
    // TODO: 实现通知取消
    print('📱 取消通知');
  }

  Future<void> showSessionCompletedNotification({
    required String sessionId,
    required String title,
    required String body,
  }) async {
    // TODO: 实现完成通知
    print('📱 显示完成通知: $title - $body');
  }
}

final notificationsProvider = StateNotifierProvider<NotificationsProvider, bool>((ref) {
  return NotificationsProvider();
});
