import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'constants.dart';

/// Common helper utilities for the mobile app
class AppHelpers {
  // Private constructor to prevent instantiation
  AppHelpers._();

  /// Formats duration for display (e.g., "25:00", "1h 30m")
  static String formatDuration(Duration duration, {bool showHours = false}) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (showHours && hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (duration.inMinutes >= 60) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// Formats timer display (always MM:SS format)
  static String formatTimer(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Formats date for display
  static String formatDate(DateTime date, {String? format}) {
    final formatter = DateFormat(format ?? AppConstants.dateFormat);
    return formatter.format(date);
  }

  /// Formats time for display
  static String formatTime(DateTime time, {bool use24Hour = true}) {
    final formatter = DateFormat(use24Hour ? 'HH:mm' : 'h:mm a');
    return formatter.format(time);
  }

  /// Formats datetime for API
  static String formatDateTimeForApi(DateTime dateTime) {
    return DateFormat(AppConstants.apiDateTimeFormat).format(dateTime.toUtc());
  }

  /// Parses datetime from API response
  static DateTime? parseDateTimeFromApi(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) return null;
    try {
      return DateTime.parse(dateTimeString).toLocal();
    } catch (e) {
      return null;
    }
  }

  /// Calculates the percentage of completion
  static double calculatePercentage(int completed, int total) {
    if (total == 0) return 0.0;
    return (completed / total * 100).clamp(0.0, 100.0);
  }

  /// Rounds percentage to specified decimal places
  static double roundPercentage(double percentage, {int decimals = 1}) {
    final factor = pow(10, decimals);
    return (percentage * factor).round() / factor;
  }

  /// Gets relative time description (e.g., "2 hours ago", "in 3 days")
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.isNegative) {
      // Future time
      final futureDiff = dateTime.difference(now);
      if (futureDiff.inDays > 0) {
        return 'in ${futureDiff.inDays} day${futureDiff.inDays == 1 ? '' : 's'}';
      } else if (futureDiff.inHours > 0) {
        return 'in ${futureDiff.inHours} hour${futureDiff.inHours == 1 ? '' : 's'}';
      } else if (futureDiff.inMinutes > 0) {
        return 'in ${futureDiff.inMinutes} minute${futureDiff.inMinutes == 1 ? '' : 's'}';
      } else {
        return 'in a few seconds';
      }
    } else {
      // Past time
      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      } else {
        return 'just now';
      }
    }
  }

  /// Checks if a date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  /// Checks if a date is tomorrow
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day;
  }

  /// Checks if a date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day;
  }

  /// Gets friendly date description (e.g., "Today", "Tomorrow", "Yesterday", or formatted date)
  static String getFriendlyDate(DateTime date) {
    if (isToday(date)) return 'Today';
    if (isTomorrow(date)) return 'Tomorrow';
    if (isYesterday(date)) return 'Yesterday';
    return formatDate(date);
  }

  /// Capitalizes the first letter of a string
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Converts task priority to display string
  static String priorityToDisplayString(String priority) {
    switch (priority.toLowerCase()) {
      case AppConstants.priorityLow:
        return 'Low';
      case AppConstants.priorityMedium:
        return 'Medium';
      case AppConstants.priorityHigh:
        return 'High';
      case AppConstants.priorityUrgent:
        return 'Urgent';
      default:
        return capitalize(priority);
    }
  }

  /// Converts task status to display string
  static String statusToDisplayString(String status) {
    switch (status.toLowerCase()) {
      case AppConstants.statusPending:
        return 'Pending';
      case AppConstants.statusInProgress:
        return 'In Progress';
      case AppConstants.statusCompleted:
        return 'Completed';
      case AppConstants.statusCancelled:
        return 'Cancelled';
      default:
        return capitalize(status);
    }
  }

  /// Gets color for task priority
  static Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case AppConstants.priorityLow:
        return Colors.green;
      case AppConstants.priorityMedium:
        return Colors.orange;
      case AppConstants.priorityHigh:
        return Colors.red;
      case AppConstants.priorityUrgent:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  /// Gets color for task status
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case AppConstants.statusPending:
        return Colors.grey;
      case AppConstants.statusInProgress:
        return Colors.blue;
      case AppConstants.statusCompleted:
        return Colors.green;
      case AppConstants.statusCancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Generates a random color for tags or categories
  static Color generateTagColor(String tag) {
    final hash = tag.hashCode;
    final r = (hash & 0xFF0000) >> 16;
    final g = (hash & 0x00FF00) >> 8;
    final b = hash & 0x0000FF;
    return Color.fromRGBO(r, g, b, 0.8);
  }

  /// Truncates text to specified length with ellipsis
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Validates if a string is a valid UUID
  static bool isValidUuid(String uuid) {
    final regex = RegExp(AppConstants.uuidPattern);
    return regex.hasMatch(uuid);
  }

  /// Generates a simple hash from a string
  static int generateHash(String input) {
    var hash = 0;
    for (int i = 0; i < input.length; i++) {
      hash = ((hash << 5) - hash + input.codeUnitAt(i)) & 0xffffffff;
    }
    return hash;
  }

  /// Debounces function calls
  static void debounce(VoidCallback callback, Duration delay) {
    Timer? timer;
    timer?.cancel();
    timer = Timer(delay, callback);
  }

  /// Shows a snackbar with standardized styling
  static void showSnackBar(
    BuildContext context,
    String message, {
    SnackBarType type = SnackBarType.info,
    Duration? duration,
    VoidCallback? action,
    String? actionLabel,
  }) {
    Color backgroundColor;
    Color textColor = Colors.white;

    switch (type) {
      case SnackBarType.success:
        backgroundColor = Colors.green;
        break;
      case SnackBarType.error:
        backgroundColor = Colors.red;
        break;
      case SnackBarType.warning:
        backgroundColor = Colors.orange;
        break;
      case SnackBarType.info:
      default:
        backgroundColor = Colors.blue;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: textColor),
        ),
        backgroundColor: backgroundColor,
        duration: duration ?? AppConstants.snackBarDuration,
        action: action != null && actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: textColor,
                onPressed: action,
              )
            : null,
      ),
    );
  }

  /// Shows a loading dialog
  static void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(message ?? 'Loading...'),
            ],
          ),
        ),
      ),
    );
  }

  /// Hides the loading dialog
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  /// Shows a confirmation dialog
  static Future<bool> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Converts seconds to Duration
  static Duration secondsToDuration(int seconds) {
    return Duration(seconds: seconds);
  }

  /// Converts Duration to seconds
  static int durationToSeconds(Duration duration) {
    return duration.inSeconds;
  }

  /// Converts minutes to Duration
  static Duration minutesToDuration(int minutes) {
    return Duration(minutes: minutes);
  }

  /// Converts Duration to minutes
  static int durationToMinutes(Duration duration) {
    return duration.inMinutes;
  }

  /// Gets the start of day for a given date
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Gets the end of day for a given date
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  /// Gets the start of week for a given date
  static DateTime startOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return startOfDay(date.subtract(Duration(days: daysFromMonday)));
  }

  /// Gets the end of week for a given date
  static DateTime endOfWeek(DateTime date) {
    final daysUntilSunday = 7 - date.weekday;
    return endOfDay(date.add(Duration(days: daysUntilSunday)));
  }

  /// Checks if device is in dark mode
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// Gets platform-appropriate back button icon
  static IconData getBackButtonIcon() {
    return Icons.arrow_back;
  }

  /// Safely navigates to a route
  static void navigateTo(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  /// Safely navigates and replaces current route
  static void navigateAndReplace(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushReplacementNamed(context, routeName, arguments: arguments);
  }

  /// Safely navigates and clears stack
  static void navigateAndClearStack(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }
}

/// Enum for snackbar types
enum SnackBarType {
  success,
  error,
  warning,
  info,
}

/// Timer for debouncing function calls
class Timer {
  static const int _frequency = 60; // 60 FPS
  static final Map<String, Timer> _timers = {};

  late final String _id;
  late final Duration _duration;
  late final VoidCallback _callback;
  late final DateTime _startTime;
  bool _isActive = false;

  Timer(Duration duration, VoidCallback callback)
      : _duration = duration,
        _callback = callback {
    _id = DateTime.now().millisecondsSinceEpoch.toString();
    _startTime = DateTime.now();
    _start();
  }

  void _start() {
    _isActive = true;
    _timers[_id] = this;
    _scheduleCallback();
  }

  void _scheduleCallback() {
    if (!_isActive) return;

    Future.delayed(Duration(milliseconds: 1000 ~/ _frequency), () {
      if (!_isActive) return;

      final elapsed = DateTime.now().difference(_startTime);
      if (elapsed >= _duration) {
        cancel();
        _callback();
      } else {
        _scheduleCallback();
      }
    });
  }

  void cancel() {
    _isActive = false;
    _timers.remove(_id);
  }

  static void cancelAll() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }
}