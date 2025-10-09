// Haptic feedback utilities
import 'package:flutter/services.dart';

class HapticUtils {
  static Future<void> lightImpact() async {
    await HapticFeedback.lightImpact();
  }

  static Future<void> mediumImpact() async {
    await HapticFeedback.mediumImpact();
  }

  static Future<void> heavyImpact() async {
    await HapticFeedback.heavyImpact();
  }

  static Future<void> selectionClick() async {
    await HapticFeedback.selectionClick();
  }

  static Future<void> pomodoroComplete() async {
    await heavyImpact();
  }

  static Future<void> breakStart() async {
    await lightImpact();
  }

  static Future<void> breakComplete() async {
    await mediumImpact();
  }
}
