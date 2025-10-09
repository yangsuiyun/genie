// Audio utilities for sound effects
import 'package:flutter/services.dart';

class AudioUtils {
  static const MethodChannel _channel = MethodChannel('audio_utils');

  static Future<void> playSound(String soundType) async {
    try {
      await _channel.invokeMethod('playSound', {'type': soundType});
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  static Future<void> playPomodoroComplete() async {
    await playSound('pomodoro_complete');
  }

  static Future<void> playBreakStart() async {
    await playSound('break_start');
  }

  static Future<void> playBreakComplete() async {
    await playSound('break_complete');
  }

  static Future<void> playNotification() async {
    await playSound('notification');
  }
}
