/// Application-wide constants for the Pomodoro Genie mobile app
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  /// API Configuration
  static const String apiBaseUrl = 'http://localhost:3000/v1';
  static const Duration apiTimeout = Duration(seconds: 30);
  static const int maxRetryAttempts = 3;

  /// Timer Configuration
  static const Duration defaultWorkDuration = Duration(minutes: 25);
  static const Duration defaultShortBreakDuration = Duration(minutes: 5);
  static const Duration defaultLongBreakDuration = Duration(minutes: 15);
  static const int defaultSessionsUntilLongBreak = 4;
  static const Duration timerUpdateInterval = Duration(milliseconds: 100);
  static const Duration timerPrecisionTolerance = Duration(seconds: 1);

  /// UI Configuration
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration snackBarDuration = Duration(seconds: 3);
  static const Duration splashScreenDuration = Duration(seconds: 2);
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 8.0;

  /// Validation Limits
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int maxTaskTitleLength = 200;
  static const int maxTaskDescriptionLength = 1000;
  static const int maxSubtaskTitleLength = 200;
  static const int maxUserNameLength = 100;
  static const int maxTagsPerTask = 20;
  static const int maxTagLength = 50;

  /// Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  /// Local Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userPreferencesKey = 'user_preferences';
  static const String lastSyncTimestampKey = 'last_sync_timestamp';
  static const String deviceIdKey = 'device_id';
  static const String offlineTasksKey = 'offline_tasks';
  static const String offlineSessionsKey = 'offline_sessions';

  /// Notification Types
  static const String sessionCompleteNotification = 'session_complete';
  static const String breakReminderNotification = 'break_reminder';
  static const String taskReminderNotification = 'task_reminder';
  static const String dailySummaryNotification = 'daily_summary';

  /// Theme Configuration
  static const String lightTheme = 'light';
  static const String darkTheme = 'dark';
  static const String systemTheme = 'system';

  /// Date and Time Formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String apiDateTimeFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'";

  /// Error Messages
  static const String networkErrorMessage = 'Network connection error. Please check your internet connection.';
  static const String serverErrorMessage = 'Server error. Please try again later.';
  static const String unauthorizedErrorMessage = 'Your session has expired. Please log in again.';
  static const String validationErrorMessage = 'Please check your input and try again.';
  static const String genericErrorMessage = 'Something went wrong. Please try again.';

  /// Success Messages
  static const String taskCreatedMessage = 'Task created successfully';
  static const String taskUpdatedMessage = 'Task updated successfully';
  static const String taskDeletedMessage = 'Task deleted successfully';
  static const String sessionCompletedMessage = 'Session completed successfully';
  static const String profileUpdatedMessage = 'Profile updated successfully';
  static const String passwordChangedMessage = 'Password changed successfully';

  /// File and Asset Paths
  static const String logoAssetPath = 'assets/images/logo.png';
  static const String iconAssetPath = 'assets/icons/';
  static const String soundAssetPath = 'assets/sounds/';

  /// Sound Files
  static const String bellSoundFile = 'bell.mp3';
  static const String chimesSoundFile = 'chimes.mp3';
  static const String notificationSoundFile = 'notification.mp3';

  /// Animation Assets
  static const String timerAnimationPath = 'assets/animations/timer.json';
  static const String successAnimationPath = 'assets/animations/success.json';
  static const String loadingAnimationPath = 'assets/animations/loading.json';

  /// HTTP Status Codes
  static const int httpOk = 200;
  static const int httpCreated = 201;
  static const int httpNoContent = 204;
  static const int httpBadRequest = 400;
  static const int httpUnauthorized = 401;
  static const int httpForbidden = 403;
  static const int httpNotFound = 404;
  static const int httpConflict = 409;
  static const int httpTooManyRequests = 429;
  static const int httpInternalServerError = 500;

  /// Task Priority Values
  static const String priorityLow = 'low';
  static const String priorityMedium = 'medium';
  static const String priorityHigh = 'high';
  static const String priorityUrgent = 'urgent';

  /// Task Status Values
  static const String statusPending = 'pending';
  static const String statusInProgress = 'in_progress';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';

  /// Session Type Values
  static const String sessionTypeWork = 'work';
  static const String sessionTypeShortBreak = 'short_break';
  static const String sessionTypeLongBreak = 'long_break';

  /// Session Status Values
  static const String sessionStatusActive = 'active';
  static const String sessionStatusPaused = 'paused';
  static const String sessionStatusCompleted = 'completed';
  static const String sessionStatusStopped = 'stopped';

  /// Sync Configuration
  static const Duration syncInterval = Duration(minutes: 5);
  static const Duration syncTimeout = Duration(seconds: 30);
  static const int maxSyncRetries = 3;
  static const int maxOfflineQueueSize = 1000;

  /// Performance Limits
  static const Duration maxTimerDuration = Duration(hours: 8);
  static const Duration minTimerDuration = Duration(minutes: 1);
  static const int maxConcurrentTimers = 1;
  static const int maxTasksPerPage = 50;

  /// Feature Flags
  static const bool enableOfflineMode = true;
  static const bool enablePushNotifications = true;
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  static const bool enableDebugMode = false; // Should be false in production

  /// Database Configuration
  static const String databaseName = 'pomodoro_genie.db';
  static const int databaseVersion = 1;
  static const String tasksTableName = 'tasks';
  static const String sessionsTableName = 'sessions';
  static const String userPreferencesTableName = 'user_preferences';

  /// Regex Patterns
  static const String emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String uuidPattern = r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$';

  /// Color Values (as hex strings)
  static const String primaryColorHex = '#2196F3';
  static const String secondaryColorHex = '#FFC107';
  static const String successColorHex = '#4CAF50';
  static const String warningColorHex = '#FF9800';
  static const String errorColorHex = '#F44336';
  static const String infoColorHex = '#2196F3';
}

/// Environment-specific constants
class EnvironmentConstants {
  // Private constructor to prevent instantiation
  EnvironmentConstants._();

  /// Current environment (dev, staging, production)
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  /// API base URL based on environment
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/v1',
  );

  /// Enable debug features
  static const bool debugMode = bool.fromEnvironment(
    'DEBUG_MODE',
    defaultValue: true,
  );

  /// Analytics tracking ID
  static const String analyticsTrackingId = String.fromEnvironment(
    'ANALYTICS_TRACKING_ID',
    defaultValue: '',
  );

  /// Crashlytics enabled
  static const bool crashlyticsEnabled = bool.fromEnvironment(
    'CRASHLYTICS_ENABLED',
    defaultValue: false,
  );
}

/// Platform-specific constants
class PlatformConstants {
  // Private constructor to prevent instantiation
  PlatformConstants._();

  /// iOS specific constants
  static const String iosAppStoreId = '1234567890';
  static const String iosUrlScheme = 'pomodoro-genie';

  /// Android specific constants
  static const String androidPackageName = 'com.pomodoro.genie';
  static const String androidPlayStoreUrl = 'https://play.google.com/store/apps/details?id=com.pomodoro.genie';

  /// Deep link configuration
  static const String deepLinkScheme = 'pomodoro-genie';
  static const String deepLinkHost = 'app';

  /// Push notification configuration
  static const String fcmSenderId = '123456789012';
  static const String fcmVapidKey = 'your-vapid-key-here';
}

/// Route names for navigation
class RouteNames {
  // Private constructor to prevent instantiation
  RouteNames._();

  // Auth routes
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verifyEmail = '/verify-email';

  // Main app routes
  static const String home = '/home';
  static const String tasks = '/tasks';
  static const String taskDetail = '/tasks/detail';
  static const String createTask = '/tasks/create';
  static const String editTask = '/tasks/edit';
  static const String timer = '/timer';
  static const String reports = '/reports';
  static const String settings = '/settings';
  static const String profile = '/profile';

  // Settings sub-routes
  static const String timerSettings = '/settings/timer';
  static const String notificationSettings = '/settings/notifications';
  static const String accountSettings = '/settings/account';
  static const String privacySettings = '/settings/privacy';
  static const String aboutSettings = '/settings/about';
}