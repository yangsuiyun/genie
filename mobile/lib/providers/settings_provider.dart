import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_storage.dart';

enum ThemeMode { system, light, dark }

enum Language { english, spanish, french, german, chinese, japanese }

class AppSettings {
  final ThemeMode themeMode;
  final Language language;
  final bool enableAnimations;
  final bool enableHapticFeedback;
  final bool showCompletedTasks;
  final bool autoDeleteCompletedTasks;
  final int autoDeleteAfterDays;
  final bool enableDeveloperMode;
  final String dateFormat;
  final String timeFormat;
  final String defaultTaskView;
  final bool enableTaskSounds;
  final double uiScale;

  AppSettings({
    this.themeMode = ThemeMode.system,
    this.language = Language.english,
    this.enableAnimations = true,
    this.enableHapticFeedback = true,
    this.showCompletedTasks = true,
    this.autoDeleteCompletedTasks = false,
    this.autoDeleteAfterDays = 30,
    this.enableDeveloperMode = false,
    this.dateFormat = 'MM/dd/yyyy',
    this.timeFormat = '12h',
    this.defaultTaskView = 'list',
    this.enableTaskSounds = true,
    this.uiScale = 1.0,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        themeMode: ThemeMode.values.firstWhere(
          (e) => e.toString().split('.').last == json['theme_mode'],
          orElse: () => ThemeMode.system,
        ),
        language: Language.values.firstWhere(
          (e) => e.toString().split('.').last == json['language'],
          orElse: () => Language.english,
        ),
        enableAnimations: json['enable_animations'] ?? true,
        enableHapticFeedback: json['enable_haptic_feedback'] ?? true,
        showCompletedTasks: json['show_completed_tasks'] ?? true,
        autoDeleteCompletedTasks: json['auto_delete_completed_tasks'] ?? false,
        autoDeleteAfterDays: json['auto_delete_after_days'] ?? 30,
        enableDeveloperMode: json['enable_developer_mode'] ?? false,
        dateFormat: json['date_format'] ?? 'MM/dd/yyyy',
        timeFormat: json['time_format'] ?? '12h',
        defaultTaskView: json['default_task_view'] ?? 'list',
        enableTaskSounds: json['enable_task_sounds'] ?? true,
        uiScale: (json['ui_scale'] ?? 1.0).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'theme_mode': themeMode.toString().split('.').last,
        'language': language.toString().split('.').last,
        'enable_animations': enableAnimations,
        'enable_haptic_feedback': enableHapticFeedback,
        'show_completed_tasks': showCompletedTasks,
        'auto_delete_completed_tasks': autoDeleteCompletedTasks,
        'auto_delete_after_days': autoDeleteAfterDays,
        'enable_developer_mode': enableDeveloperMode,
        'date_format': dateFormat,
        'time_format': timeFormat,
        'default_task_view': defaultTaskView,
        'enable_task_sounds': enableTaskSounds,
        'ui_scale': uiScale,
      };

  AppSettings copyWith({
    ThemeMode? themeMode,
    Language? language,
    bool? enableAnimations,
    bool? enableHapticFeedback,
    bool? showCompletedTasks,
    bool? autoDeleteCompletedTasks,
    int? autoDeleteAfterDays,
    bool? enableDeveloperMode,
    String? dateFormat,
    String? timeFormat,
    String? defaultTaskView,
    bool? enableTaskSounds,
    double? uiScale,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        language: language ?? this.language,
        enableAnimations: enableAnimations ?? this.enableAnimations,
        enableHapticFeedback: enableHapticFeedback ?? this.enableHapticFeedback,
        showCompletedTasks: showCompletedTasks ?? this.showCompletedTasks,
        autoDeleteCompletedTasks: autoDeleteCompletedTasks ?? this.autoDeleteCompletedTasks,
        autoDeleteAfterDays: autoDeleteAfterDays ?? this.autoDeleteAfterDays,
        enableDeveloperMode: enableDeveloperMode ?? this.enableDeveloperMode,
        dateFormat: dateFormat ?? this.dateFormat,
        timeFormat: timeFormat ?? this.timeFormat,
        defaultTaskView: defaultTaskView ?? this.defaultTaskView,
        enableTaskSounds: enableTaskSounds ?? this.enableTaskSounds,
        uiScale: uiScale ?? this.uiScale,
      );

  String get languageName {
    switch (language) {
      case Language.english:
        return 'English';
      case Language.spanish:
        return 'Español';
      case Language.french:
        return 'Français';
      case Language.german:
        return 'Deutsch';
      case Language.chinese:
        return '中文';
      case Language.japanese:
        return '日本語';
    }
  }

  String get languageCode {
    switch (language) {
      case Language.english:
        return 'en';
      case Language.spanish:
        return 'es';
      case Language.french:
        return 'fr';
      case Language.german:
        return 'de';
      case Language.chinese:
        return 'zh';
      case Language.japanese:
        return 'ja';
    }
  }
}

class PrivacySettings {
  final bool enableAnalytics;
  final bool enableCrashReporting;
  final bool enableUsageTracking;
  final bool shareAnonymousData;
  final bool enableLocationServices;
  final bool allowNotificationTracking;
  final bool enableBiometricAuth;
  final bool autoLockEnabled;
  final int autoLockTimeoutMinutes;

  PrivacySettings({
    this.enableAnalytics = true,
    this.enableCrashReporting = true,
    this.enableUsageTracking = false,
    this.shareAnonymousData = true,
    this.enableLocationServices = false,
    this.allowNotificationTracking = true,
    this.enableBiometricAuth = false,
    this.autoLockEnabled = false,
    this.autoLockTimeoutMinutes = 5,
  });

  factory PrivacySettings.fromJson(Map<String, dynamic> json) => PrivacySettings(
        enableAnalytics: json['enable_analytics'] ?? true,
        enableCrashReporting: json['enable_crash_reporting'] ?? true,
        enableUsageTracking: json['enable_usage_tracking'] ?? false,
        shareAnonymousData: json['share_anonymous_data'] ?? true,
        enableLocationServices: json['enable_location_services'] ?? false,
        allowNotificationTracking: json['allow_notification_tracking'] ?? true,
        enableBiometricAuth: json['enable_biometric_auth'] ?? false,
        autoLockEnabled: json['auto_lock_enabled'] ?? false,
        autoLockTimeoutMinutes: json['auto_lock_timeout_minutes'] ?? 5,
      );

  Map<String, dynamic> toJson() => {
        'enable_analytics': enableAnalytics,
        'enable_crash_reporting': enableCrashReporting,
        'enable_usage_tracking': enableUsageTracking,
        'share_anonymous_data': shareAnonymousData,
        'enable_location_services': enableLocationServices,
        'allow_notification_tracking': allowNotificationTracking,
        'enable_biometric_auth': enableBiometricAuth,
        'auto_lock_enabled': autoLockEnabled,
        'auto_lock_timeout_minutes': autoLockTimeoutMinutes,
      };

  PrivacySettings copyWith({
    bool? enableAnalytics,
    bool? enableCrashReporting,
    bool? enableUsageTracking,
    bool? shareAnonymousData,
    bool? enableLocationServices,
    bool? allowNotificationTracking,
    bool? enableBiometricAuth,
    bool? autoLockEnabled,
    int? autoLockTimeoutMinutes,
  }) =>
      PrivacySettings(
        enableAnalytics: enableAnalytics ?? this.enableAnalytics,
        enableCrashReporting: enableCrashReporting ?? this.enableCrashReporting,
        enableUsageTracking: enableUsageTracking ?? this.enableUsageTracking,
        shareAnonymousData: shareAnonymousData ?? this.shareAnonymousData,
        enableLocationServices: enableLocationServices ?? this.enableLocationServices,
        allowNotificationTracking: allowNotificationTracking ?? this.allowNotificationTracking,
        enableBiometricAuth: enableBiometricAuth ?? this.enableBiometricAuth,
        autoLockEnabled: autoLockEnabled ?? this.autoLockEnabled,
        autoLockTimeoutMinutes: autoLockTimeoutMinutes ?? this.autoLockTimeoutMinutes,
      );
}

class ProductivitySettings {
  final bool enableFocusMode;
  final List<String> focusModeBlockedApps;
  final bool showProductivityTips;
  final bool enableBreakReminders;
  final int breakReminderIntervalMinutes;
  final bool enableGoalTracking;
  final int dailyPomodoroGoal;
  final int dailyTaskGoal;
  final bool enableWeeklyReview;
  final String weeklyReviewDay;
  final bool enableTimeTracking;
  final bool showTimeSpentOnTasks;

  ProductivitySettings({
    this.enableFocusMode = false,
    this.focusModeBlockedApps = const [],
    this.showProductivityTips = true,
    this.enableBreakReminders = true,
    this.breakReminderIntervalMinutes = 60,
    this.enableGoalTracking = true,
    this.dailyPomodoroGoal = 8,
    this.dailyTaskGoal = 5,
    this.enableWeeklyReview = true,
    this.weeklyReviewDay = 'sunday',
    this.enableTimeTracking = true,
    this.showTimeSpentOnTasks = true,
  });

  factory ProductivitySettings.fromJson(Map<String, dynamic> json) => ProductivitySettings(
        enableFocusMode: json['enable_focus_mode'] ?? false,
        focusModeBlockedApps: List<String>.from(json['focus_mode_blocked_apps'] ?? []),
        showProductivityTips: json['show_productivity_tips'] ?? true,
        enableBreakReminders: json['enable_break_reminders'] ?? true,
        breakReminderIntervalMinutes: json['break_reminder_interval_minutes'] ?? 60,
        enableGoalTracking: json['enable_goal_tracking'] ?? true,
        dailyPomodoroGoal: json['daily_pomodoro_goal'] ?? 8,
        dailyTaskGoal: json['daily_task_goal'] ?? 5,
        enableWeeklyReview: json['enable_weekly_review'] ?? true,
        weeklyReviewDay: json['weekly_review_day'] ?? 'sunday',
        enableTimeTracking: json['enable_time_tracking'] ?? true,
        showTimeSpentOnTasks: json['show_time_spent_on_tasks'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'enable_focus_mode': enableFocusMode,
        'focus_mode_blocked_apps': focusModeBlockedApps,
        'show_productivity_tips': showProductivityTips,
        'enable_break_reminders': enableBreakReminders,
        'break_reminder_interval_minutes': breakReminderIntervalMinutes,
        'enable_goal_tracking': enableGoalTracking,
        'daily_pomodoro_goal': dailyPomodoroGoal,
        'daily_task_goal': dailyTaskGoal,
        'enable_weekly_review': enableWeeklyReview,
        'weekly_review_day': weeklyReviewDay,
        'enable_time_tracking': enableTimeTracking,
        'show_time_spent_on_tasks': showTimeSpentOnTasks,
      };

  ProductivitySettings copyWith({
    bool? enableFocusMode,
    List<String>? focusModeBlockedApps,
    bool? showProductivityTips,
    bool? enableBreakReminders,
    int? breakReminderIntervalMinutes,
    bool? enableGoalTracking,
    int? dailyPomodoroGoal,
    int? dailyTaskGoal,
    bool? enableWeeklyReview,
    String? weeklyReviewDay,
    bool? enableTimeTracking,
    bool? showTimeSpentOnTasks,
  }) =>
      ProductivitySettings(
        enableFocusMode: enableFocusMode ?? this.enableFocusMode,
        focusModeBlockedApps: focusModeBlockedApps ?? this.focusModeBlockedApps,
        showProductivityTips: showProductivityTips ?? this.showProductivityTips,
        enableBreakReminders: enableBreakReminders ?? this.enableBreakReminders,
        breakReminderIntervalMinutes: breakReminderIntervalMinutes ?? this.breakReminderIntervalMinutes,
        enableGoalTracking: enableGoalTracking ?? this.enableGoalTracking,
        dailyPomodoroGoal: dailyPomodoroGoal ?? this.dailyPomodoroGoal,
        dailyTaskGoal: dailyTaskGoal ?? this.dailyTaskGoal,
        enableWeeklyReview: enableWeeklyReview ?? this.enableWeeklyReview,
        weeklyReviewDay: weeklyReviewDay ?? this.weeklyReviewDay,
        enableTimeTracking: enableTimeTracking ?? this.enableTimeTracking,
        showTimeSpentOnTasks: showTimeSpentOnTasks ?? this.showTimeSpentOnTasks,
      );
}

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier() : super(AppSettings()) {
    _initialize();
  }

  final LocalStorage _localStorage = LocalStorage.instance;

  Future<void> _initialize() async {
    await _localStorage.initialize();

    final settingsData = _localStorage.getAllSettings();
    state = AppSettings.fromJson(settingsData);
  }

  Future<void> updateSettings({
    ThemeMode? themeMode,
    Language? language,
    bool? enableAnimations,
    bool? enableHapticFeedback,
    bool? showCompletedTasks,
    bool? autoDeleteCompletedTasks,
    int? autoDeleteAfterDays,
    bool? enableDeveloperMode,
    String? dateFormat,
    String? timeFormat,
    String? defaultTaskView,
    bool? enableTaskSounds,
    double? uiScale,
  }) async {
    final newSettings = state.copyWith(
      themeMode: themeMode,
      language: language,
      enableAnimations: enableAnimations,
      enableHapticFeedback: enableHapticFeedback,
      showCompletedTasks: showCompletedTasks,
      autoDeleteCompletedTasks: autoDeleteCompletedTasks,
      autoDeleteAfterDays: autoDeleteAfterDays,
      enableDeveloperMode: enableDeveloperMode,
      dateFormat: dateFormat,
      timeFormat: timeFormat,
      defaultTaskView: defaultTaskView,
      enableTaskSounds: enableTaskSounds,
      uiScale: uiScale,
    );

    await _localStorage.saveSettings(newSettings.toJson());
    state = newSettings;
  }

  Future<void> resetToDefaults() async {
    final defaultSettings = AppSettings();
    await _localStorage.saveSettings(defaultSettings.toJson());
    state = defaultSettings;
  }
}

class PrivacySettingsNotifier extends StateNotifier<PrivacySettings> {
  PrivacySettingsNotifier() : super(PrivacySettings()) {
    _initialize();
  }

  final LocalStorage _localStorage = LocalStorage.instance;

  Future<void> _initialize() async {
    await _localStorage.initialize();

    final settingsData = _localStorage.getAllSettings();
    state = PrivacySettings.fromJson(settingsData);
  }

  Future<void> updateSettings({
    bool? enableAnalytics,
    bool? enableCrashReporting,
    bool? enableUsageTracking,
    bool? shareAnonymousData,
    bool? enableLocationServices,
    bool? allowNotificationTracking,
    bool? enableBiometricAuth,
    bool? autoLockEnabled,
    int? autoLockTimeoutMinutes,
  }) async {
    final newSettings = state.copyWith(
      enableAnalytics: enableAnalytics,
      enableCrashReporting: enableCrashReporting,
      enableUsageTracking: enableUsageTracking,
      shareAnonymousData: shareAnonymousData,
      enableLocationServices: enableLocationServices,
      allowNotificationTracking: allowNotificationTracking,
      enableBiometricAuth: enableBiometricAuth,
      autoLockEnabled: autoLockEnabled,
      autoLockTimeoutMinutes: autoLockTimeoutMinutes,
    );

    await _localStorage.saveSettings(newSettings.toJson());
    state = newSettings;
  }

  Future<void> resetToDefaults() async {
    final defaultSettings = PrivacySettings();
    await _localStorage.saveSettings(defaultSettings.toJson());
    state = defaultSettings;
  }
}

class ProductivitySettingsNotifier extends StateNotifier<ProductivitySettings> {
  ProductivitySettingsNotifier() : super(ProductivitySettings()) {
    _initialize();
  }

  final LocalStorage _localStorage = LocalStorage.instance;

  Future<void> _initialize() async {
    await _localStorage.initialize();

    final settingsData = _localStorage.getAllSettings();
    state = ProductivitySettings.fromJson(settingsData);
  }

  Future<void> updateSettings({
    bool? enableFocusMode,
    List<String>? focusModeBlockedApps,
    bool? showProductivityTips,
    bool? enableBreakReminders,
    int? breakReminderIntervalMinutes,
    bool? enableGoalTracking,
    int? dailyPomodoroGoal,
    int? dailyTaskGoal,
    bool? enableWeeklyReview,
    String? weeklyReviewDay,
    bool? enableTimeTracking,
    bool? showTimeSpentOnTasks,
  }) async {
    final newSettings = state.copyWith(
      enableFocusMode: enableFocusMode,
      focusModeBlockedApps: focusModeBlockedApps,
      showProductivityTips: showProductivityTips,
      enableBreakReminders: enableBreakReminders,
      breakReminderIntervalMinutes: breakReminderIntervalMinutes,
      enableGoalTracking: enableGoalTracking,
      dailyPomodoroGoal: dailyPomodoroGoal,
      dailyTaskGoal: dailyTaskGoal,
      enableWeeklyReview: enableWeeklyReview,
      weeklyReviewDay: weeklyReviewDay,
      enableTimeTracking: enableTimeTracking,
      showTimeSpentOnTasks: showTimeSpentOnTasks,
    );

    await _localStorage.saveSettings(newSettings.toJson());
    state = newSettings;
  }

  Future<void> resetToDefaults() async {
    final defaultSettings = ProductivitySettings();
    await _localStorage.saveSettings(defaultSettings.toJson());
    state = defaultSettings;
  }
}

// Provider definitions
final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  return AppSettingsNotifier();
});

final privacySettingsProvider = StateNotifierProvider<PrivacySettingsNotifier, PrivacySettings>((ref) {
  return PrivacySettingsNotifier();
});

final productivitySettingsProvider = StateNotifierProvider<ProductivitySettingsNotifier, ProductivitySettings>((ref) {
  return ProductivitySettingsNotifier();
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(appSettingsProvider).themeMode;
});

final languageProvider = Provider<Language>((ref) {
  return ref.watch(appSettingsProvider).language;
});

final isDeveloperModeProvider = Provider<bool>((ref) {
  return ref.watch(appSettingsProvider).enableDeveloperMode;
});

final enableAnimationsProvider = Provider<bool>((ref) {
  return ref.watch(appSettingsProvider).enableAnimations;
});

final enableHapticFeedbackProvider = Provider<bool>((ref) {
  return ref.watch(appSettingsProvider).enableHapticFeedback;
});

final uiScaleProvider = Provider<double>((ref) {
  return ref.watch(appSettingsProvider).uiScale;
});

final enableAnalyticsProvider = Provider<bool>((ref) {
  return ref.watch(privacySettingsProvider).enableAnalytics;
});

final enableBiometricAuthProvider = Provider<bool>((ref) {
  return ref.watch(privacySettingsProvider).enableBiometricAuth;
});

final dailyPomodoroGoalProvider = Provider<int>((ref) {
  return ref.watch(productivitySettingsProvider).dailyPomodoroGoal;
});

final dailyTaskGoalProvider = Provider<int>((ref) {
  return ref.watch(productivitySettingsProvider).dailyTaskGoal;
});

final enableGoalTrackingProvider = Provider<bool>((ref) {
  return ref.watch(productivitySettingsProvider).enableGoalTracking;
});