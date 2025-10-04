import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../models/api_response.dart';
import '../models/offline_operation.dart';
import '../utils/constants.dart';
import 'local_storage.dart';

class ApiClient {
  static ApiClient? _instance;
  static ApiClient get instance => _instance ??= ApiClient._();

  ApiClient._() {
    _initializeDio();
    _initializeConnectivity();
    _initializeOfflineQueue();
  }

  // Dependencies
  late Dio _dio;
  late Connectivity _connectivity;
  late LocalStorage _localStorage;

  // State
  bool _isOnline = true;
  String? _authToken;
  String? _refreshToken;
  Timer? _retryTimer;
  final List<OfflineOperation> _offlineQueue = [];
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();
  final StreamController<List<OfflineOperation>> _queueController = StreamController<List<OfflineOperation>>.broadcast();

  // Configuration
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 5);
  static const Duration _connectTimeout = Duration(seconds: 30);
  static const Duration _receiveTimeout = Duration(seconds: 30);
  static const Duration _sendTimeout = Duration(seconds: 30);

  // Getters
  bool get isOnline => _isOnline;
  bool get hasAuthToken => _authToken != null;
  Stream<bool> get connectivityStream => _connectivityController.stream;
  Stream<List<OfflineOperation>> get queueStream => _queueController.stream;
  List<OfflineOperation> get pendingOperations => List.unmodifiable(_offlineQueue);
  int get queueSize => _offlineQueue.length;

  // Initialize Dio HTTP client
  void _initializeDio() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: _connectTimeout,
      receiveTimeout: _receiveTimeout,
      sendTimeout: _sendTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Request interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Add auth token if available
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }

        // Add device info
        options.headers['X-Device-Platform'] = Platform.operatingSystem;
        options.headers['X-App-Version'] = ApiConstants.appVersion;

        if (kDebugMode) {
          print('🚀 API Request: ${options.method} ${options.path}');
          print('📝 Headers: ${options.headers}');
          if (options.data != null) {
            print('📦 Data: ${options.data}');
          }
        }

        handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          print('✅ API Response: ${response.statusCode} ${response.requestOptions.path}');
          print('📄 Data: ${response.data}');
        }
        handler.next(response);
      },
      onError: (error, handler) {
        if (kDebugMode) {
          print('❌ API Error: ${error.response?.statusCode} ${error.requestOptions.path}');
          print('📄 Error: ${error.message}');
          print('📄 Response: ${error.response?.data}');
        }

        // Handle token expiration
        if (error.response?.statusCode == 401) {
          _handleTokenExpiration(error, handler);
          return;
        }

        handler.next(error);
      },
    ));
  }

  // Initialize connectivity monitoring
  void _initializeConnectivity() {
    _connectivity = Connectivity();
    _localStorage = LocalStorage.instance;

    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;

      if (kDebugMode) {
        print('🌐 Connectivity changed: ${_isOnline ? 'Online' : 'Offline'}');
      }

      _connectivityController.add(_isOnline);

      // Process offline queue when coming back online
      if (!wasOnline && _isOnline) {
        _processOfflineQueue();
      }
    });

    // Check initial connectivity
    _checkInitialConnectivity();
  }

  Future<void> _checkInitialConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _isOnline = result != ConnectivityResult.none;
      _connectivityController.add(_isOnline);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking connectivity: $e');
      }
      _isOnline = false;
    }
  }

  // Initialize offline queue from storage
  void _initializeOfflineQueue() async {
    try {
      final savedOperations = await _localStorage.getOfflineOperations();
      _offlineQueue.addAll(savedOperations);
      _queueController.add(List.from(_offlineQueue));

      if (kDebugMode) {
        print('📱 Loaded ${_offlineQueue.length} offline operations from storage');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading offline queue: $e');
      }
    }
  }

  // Authentication methods
  Future<void> setAuthTokens(String accessToken, String refreshToken) async {
    _authToken = accessToken;
    _refreshToken = refreshToken;
    await _localStorage.saveAuthTokens(accessToken, refreshToken);
  }

  Future<void> clearAuthTokens() async {
    _authToken = null;
    _refreshToken = null;
    await _localStorage.clearAuthTokens();
  }

  Future<void> _loadAuthTokens() async {
    final tokens = await _localStorage.getAuthTokens();
    _authToken = tokens['accessToken'];
    _refreshToken = tokens['refreshToken'];
  }

  // Handle token expiration and refresh
  Future<void> _handleTokenExpiration(DioException error, ErrorInterceptorHandler handler) async {
    if (_refreshToken != null) {
      try {
        final response = await _dio.post('/auth/refresh', data: {
          'refresh_token': _refreshToken,
        });

        if (response.statusCode == 200) {
          final newAccessToken = response.data['access_token'];
          final newRefreshToken = response.data['refresh_token'];

          await setAuthTokens(newAccessToken, newRefreshToken);

          // Retry the original request
          final options = error.requestOptions;
          options.headers['Authorization'] = 'Bearer $newAccessToken';

          final retryResponse = await _dio.fetch(options);
          handler.resolve(retryResponse);
          return;
        }
      } catch (refreshError) {
        if (kDebugMode) {
          print('❌ Token refresh failed: $refreshError');
        }
        // Clear tokens and let the error propagate
        await clearAuthTokens();
      }
    }

    handler.next(error);
  }

  // Core API methods
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
    bool enableOffline = true,
  }) async {
    return _makeRequest<T>(
      'GET',
      path,
      queryParameters: queryParameters,
      requiresAuth: requiresAuth,
      enableOffline: enableOffline,
    );
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
    bool enableOffline = true,
  }) async {
    return _makeRequest<T>(
      'POST',
      path,
      data: data,
      queryParameters: queryParameters,
      requiresAuth: requiresAuth,
      enableOffline: enableOffline,
    );
  }

  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
    bool enableOffline = true,
  }) async {
    return _makeRequest<T>(
      'PUT',
      path,
      data: data,
      queryParameters: queryParameters,
      requiresAuth: requiresAuth,
      enableOffline: enableOffline,
    );
  }

  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
    bool enableOffline = true,
  }) async {
    return _makeRequest<T>(
      'DELETE',
      path,
      data: data,
      queryParameters: queryParameters,
      requiresAuth: requiresAuth,
      enableOffline: enableOffline,
    );
  }

  // Core request method with offline support
  Future<ApiResponse<T>> _makeRequest<T>(
    String method,
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
    bool enableOffline = true,
  }) async {
    // Check auth requirements
    if (requiresAuth && !hasAuthToken) {
      return ApiResponse<T>.error('Authentication required');
    }

    // If offline and operation supports offline mode, queue it
    if (!_isOnline && enableOffline && _isWriteOperation(method)) {
      return _queueOfflineOperation<T>(method, path, data, queryParameters);
    }

    try {
      final Response response = await _dio.request(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(method: method),
      );

      return _handleSuccessResponse<T>(response);
    } on DioException catch (e) {
      return _handleDioError<T>(e, method, path, data, queryParameters, enableOffline);
    } catch (e) {
      return ApiResponse<T>.error('Unexpected error: $e');
    }
  }

  // Handle successful responses
  ApiResponse<T> _handleSuccessResponse<T>(Response response) {
    try {
      return ApiResponse<T>.success(
        data: response.data,
        statusCode: response.statusCode,
        headers: response.headers.map,
      );
    } catch (e) {
      return ApiResponse<T>.error('Failed to parse response: $e');
    }
  }

  // Handle Dio errors
  ApiResponse<T> _handleDioError<T>(
    DioException error,
    String method,
    String path,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    bool enableOffline,
  ) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        if (enableOffline && _isWriteOperation(method)) {
          return _queueOfflineOperation<T>(method, path, data, queryParameters);
        }
        return ApiResponse<T>.error('Request timeout');

      case DioExceptionType.connectionError:
        if (enableOffline && _isWriteOperation(method)) {
          return _queueOfflineOperation<T>(method, path, data, queryParameters);
        }
        return ApiResponse<T>.error('Connection error');

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] ?? 'Server error';
        return ApiResponse<T>.error(
          message,
          statusCode: statusCode,
          data: error.response?.data,
        );

      default:
        return ApiResponse<T>.error('Network error: ${error.message}');
    }
  }

  // Check if operation is a write operation
  bool _isWriteOperation(String method) {
    return ['POST', 'PUT', 'DELETE', 'PATCH'].contains(method.toUpperCase());
  }

  // Queue offline operation
  ApiResponse<T> _queueOfflineOperation<T>(
    String method,
    String path,
    dynamic data,
    Map<String, dynamic>? queryParameters,
  ) {
    final operation = OfflineOperation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      method: method,
      path: path,
      data: data,
      queryParameters: queryParameters,
      timestamp: DateTime.now(),
      retries: 0,
    );

    _offlineQueue.add(operation);
    _saveOfflineQueue();
    _queueController.add(List.from(_offlineQueue));

    if (kDebugMode) {
      print('📱 Queued offline operation: $method $path');
    }

    return ApiResponse<T>.success(
      data: null,
      isFromCache: true,
      message: 'Operation queued for when online',
    );
  }

  // Process offline queue when online
  Future<void> _processOfflineQueue() async {
    if (_offlineQueue.isEmpty || !_isOnline) return;

    if (kDebugMode) {
      print('🔄 Processing ${_offlineQueue.length} offline operations');
    }

    final operationsToProcess = List<OfflineOperation>.from(_offlineQueue);

    for (final operation in operationsToProcess) {
      try {
        await _executeOfflineOperation(operation);
        _offlineQueue.remove(operation);
      } catch (e) {
        if (kDebugMode) {
          print('❌ Failed to execute offline operation: $e');
        }

        operation.retries++;
        if (operation.retries >= _maxRetries) {
          _offlineQueue.remove(operation);
          if (kDebugMode) {
            print('🗑️ Removed operation after max retries: ${operation.path}');
          }
        }
      }
    }

    await _saveOfflineQueue();
    _queueController.add(List.from(_offlineQueue));

    if (kDebugMode) {
      print('✅ Finished processing offline queue. ${_offlineQueue.length} operations remaining');
    }
  }

  // Execute a single offline operation
  Future<void> _executeOfflineOperation(OfflineOperation operation) async {
    final response = await _dio.request(
      operation.path,
      data: operation.data,
      queryParameters: operation.queryParameters,
      options: Options(method: operation.method),
    );

    if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
      if (kDebugMode) {
        print('✅ Successfully executed offline operation: ${operation.method} ${operation.path}');
      }
    } else {
      throw Exception('Server returned status ${response.statusCode}');
    }
  }

  // Save offline queue to storage
  Future<void> _saveOfflineQueue() async {
    try {
      await _localStorage.saveOfflineOperations(_offlineQueue);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving offline queue: $e');
      }
    }
  }

  // Retry failed operations
  Future<void> retryFailedOperations() async {
    if (!_isOnline) {
      throw Exception('Cannot retry operations while offline');
    }

    await _processOfflineQueue();
  }

  // Clear offline queue
  Future<void> clearOfflineQueue() async {
    _offlineQueue.clear();
    await _saveOfflineQueue();
    _queueController.add(List.from(_offlineQueue));
  }

  // Remove specific operation from queue
  Future<void> removeFromQueue(String operationId) async {
    _offlineQueue.removeWhere((op) => op.id == operationId);
    await _saveOfflineQueue();
    _queueController.add(List.from(_offlineQueue));
  }

  // Upload file with progress
  Future<ApiResponse<T>> uploadFile<T>(
    String path,
    File file, {
    String fieldName = 'file',
    Map<String, dynamic>? additionalData,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
        ...?additionalData,
      });

      final response = await _dio.post(
        path,
        data: formData,
        onSendProgress: onProgress,
      );

      return _handleSuccessResponse<T>(response);
    } on DioException catch (e) {
      return _handleDioError<T>(e, 'POST', path, null, null, false);
    } catch (e) {
      return ApiResponse<T>.error('Upload failed: $e');
    }
  }

  // Download file with progress
  Future<ApiResponse<void>> downloadFile(
    String url,
    String savePath, {
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      await _dio.download(
        url,
        savePath,
        onReceiveProgress: onProgress,
        cancelToken: cancelToken,
      );

      return ApiResponse<void>.success(data: null);
    } on DioException catch (e) {
      return _handleDioError<void>(e, 'GET', url, null, null, false);
    } catch (e) {
      return ApiResponse<void>.error('Download failed: $e');
    }
  }

  // Batch operations
  Future<List<ApiResponse<T>>> batch<T>(List<Future<ApiResponse<T>>> requests) async {
    return await Future.wait(requests);
  }

  // Cache management
  Future<void> clearCache() async {
    try {
      // Clear Dio cache if using dio_cache_interceptor
      // await _cacheStore.deleteAll();
      if (kDebugMode) {
        print('🗑️ API cache cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing cache: $e');
      }
    }
  }

  // Health check
  Future<bool> healthCheck() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Get API status
  Map<String, dynamic> getStatus() {
    return {
      'isOnline': _isOnline,
      'hasAuthToken': hasAuthToken,
      'queueSize': _offlineQueue.length,
      'baseUrl': _dio.options.baseUrl,
      'connectTimeout': _dio.options.connectTimeout?.inMilliseconds,
      'receiveTimeout': _dio.options.receiveTimeout?.inMilliseconds,
    };
  }

  // Cleanup
  void dispose() {
    _retryTimer?.cancel();
    _connectivityController.close();
    _queueController.close();
    _dio.close();
  }
}

// API Constants
class ApiConstants {
  static const String baseUrl = 'https://api.pomodoro-app.com/v1';
  static const String appVersion = '1.0.0';

  // Endpoints
  static const String auth = '/auth';
  static const String tasks = '/tasks';
  static const String subtasks = '/subtasks';
  static const String pomodoro = '/pomodoro';
  static const String notes = '/notes';
  static const String reminders = '/reminders';
  static const String reports = '/reports';
  static const String sync = '/sync';
  static const String notifications = '/notifications';

  // Auth endpoints
  static const String login = '$auth/login';
  static const String register = '$auth/register';
  static const String logout = '$auth/logout';
  static const String refresh = '$auth/refresh';
  static const String forgotPassword = '$auth/forgot-password';
  static const String resetPassword = '$auth/reset-password';
  static const String verifyEmail = '$auth/verify-email';
  static const String changePassword = '$auth/change-password';

  // Task endpoints
  static const String createTask = tasks;
  static const String getTasks = tasks;
  static String getTask(String id) => '$tasks/$id';
  static String updateTask(String id) => '$tasks/$id';
  static String deleteTask(String id) => '$tasks/$id';
  static String duplicateTask(String id) => '$tasks/$id/duplicate';

  // Subtask endpoints
  static String getSubtasks(String taskId) => '$tasks/$taskId/subtasks';
  static String createSubtask(String taskId) => '$tasks/$taskId/subtasks';
  static String updateSubtask(String taskId, String subtaskId) => '$tasks/$taskId/subtasks/$subtaskId';
  static String deleteSubtask(String taskId, String subtaskId) => '$tasks/$taskId/subtasks/$subtaskId';

  // Pomodoro endpoints
  static const String startSession = '$pomodoro/sessions';
  static const String getSessions = '$pomodoro/sessions';
  static String getSession(String id) => '$pomodoro/sessions/$id';
  static String updateSession(String id) => '$pomodoro/sessions/$id';
  static String pauseSession(String id) => '$pomodoro/sessions/$id/pause';
  static String resumeSession(String id) => '$pomodoro/sessions/$id/resume';
  static String completeSession(String id) => '$pomodoro/sessions/$id/complete';
  static String cancelSession(String id) => '$pomodoro/sessions/$id/cancel';

  // Notes endpoints
  static const String createNote = notes;
  static const String getNotes = notes;
  static String getNote(String id) => '$notes/$id';
  static String updateNote(String id) => '$notes/$id';
  static String deleteNote(String id) => '$notes/$id';
  static String getTaskNotes(String taskId) => '$tasks/$taskId/notes';

  // Reports endpoints
  static const String generateReport = reports;
  static const String getReports = reports;
  static String getReport(String id) => '$reports/$id';
  static String exportReport(String id) => '$reports/$id/export';

  // Sync endpoints
  static const String syncData = sync;
  static const String syncStatus = '$sync/status';
  static const String syncConflicts = '$sync/conflicts';

  // File upload endpoints
  static const String uploadAvatar = '/upload/avatar';
  static const String uploadAttachment = '/upload/attachment';
}

// Specialized API clients for different domains
class AuthApiClient {
  static final ApiClient _client = ApiClient.instance;

  static Future<ApiResponse<Map<String, dynamic>>> login(String email, String password) {
    return _client.post(ApiConstants.login, data: {
      'email': email,
      'password': password,
    }, requiresAuth: false);
  }

  static Future<ApiResponse<Map<String, dynamic>>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) {
    return _client.post(ApiConstants.register, data: {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'password': password,
    }, requiresAuth: false);
  }

  static Future<ApiResponse<void>> logout() {
    return _client.post(ApiConstants.logout);
  }

  static Future<ApiResponse<void>> forgotPassword(String email) {
    return _client.post(ApiConstants.forgotPassword, data: {
      'email': email,
    }, requiresAuth: false);
  }

  static Future<ApiResponse<void>> resetPassword(String token, String password) {
    return _client.post(ApiConstants.resetPassword, data: {
      'token': token,
      'password': password,
    }, requiresAuth: false);
  }

  static Future<ApiResponse<void>> verifyEmail(String token) {
    return _client.post(ApiConstants.verifyEmail, data: {
      'token': token,
    }, requiresAuth: false);
  }

  static Future<ApiResponse<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _client.post(ApiConstants.changePassword, data: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }
}

class TasksApiClient {
  static final ApiClient _client = ApiClient.instance;

  static Future<ApiResponse<List<Map<String, dynamic>>>> getTasks({
    int page = 1,
    int limit = 20,
    String? status,
    String? priority,
    List<String>? tags,
    String? search,
    String? sortBy,
    bool sortDescending = false,
  }) {
    return _client.get(ApiConstants.getTasks, queryParameters: {
      'page': page,
      'limit': limit,
      if (status != null) 'status': status,
      if (priority != null) 'priority': priority,
      if (tags != null && tags.isNotEmpty) 'tags': tags.join(','),
      if (search != null && search.isNotEmpty) 'search': search,
      if (sortBy != null) 'sort_by': sortBy,
      'sort_desc': sortDescending,
    });
  }

  static Future<ApiResponse<Map<String, dynamic>>> getTask(String id) {
    return _client.get(ApiConstants.getTask(id));
  }

  static Future<ApiResponse<Map<String, dynamic>>> createTask(Map<String, dynamic> taskData) {
    return _client.post(ApiConstants.createTask, data: taskData);
  }

  static Future<ApiResponse<Map<String, dynamic>>> updateTask(String id, Map<String, dynamic> updates) {
    return _client.put(ApiConstants.updateTask(id), data: updates);
  }

  static Future<ApiResponse<void>> deleteTask(String id) {
    return _client.delete(ApiConstants.deleteTask(id));
  }

  static Future<ApiResponse<Map<String, dynamic>>> duplicateTask(String id) {
    return _client.post(ApiConstants.duplicateTask(id));
  }
}

class PomodoroApiClient {
  static final ApiClient _client = ApiClient.instance;

  static Future<ApiResponse<Map<String, dynamic>>> startSession(Map<String, dynamic> sessionData) {
    return _client.post(ApiConstants.startSession, data: sessionData);
  }

  static Future<ApiResponse<List<Map<String, dynamic>>>> getSessions({
    int page = 1,
    int limit = 20,
    String? status,
    String? taskId,
    String? dateFrom,
    String? dateTo,
  }) {
    return _client.get(ApiConstants.getSessions, queryParameters: {
      'page': page,
      'limit': limit,
      if (status != null) 'status': status,
      if (taskId != null) 'task_id': taskId,
      if (dateFrom != null) 'date_from': dateFrom,
      if (dateTo != null) 'date_to': dateTo,
    });
  }

  static Future<ApiResponse<Map<String, dynamic>>> updateSession(String id, Map<String, dynamic> updates) {
    return _client.put(ApiConstants.updateSession(id), data: updates);
  }

  static Future<ApiResponse<Map<String, dynamic>>> pauseSession(String id) {
    return _client.post(ApiConstants.pauseSession(id));
  }

  static Future<ApiResponse<Map<String, dynamic>>> resumeSession(String id) {
    return _client.post(ApiConstants.resumeSession(id));
  }

  static Future<ApiResponse<Map<String, dynamic>>> completeSession(String id, {
    int? productivityRating,
    int? focusRating,
    String? notes,
    int? interruptions,
    List<String>? interruptionNotes,
  }) {
    return _client.post(ApiConstants.completeSession(id), data: {
      if (productivityRating != null) 'productivity_rating': productivityRating,
      if (focusRating != null) 'focus_rating': focusRating,
      if (notes != null) 'notes': notes,
      if (interruptions != null) 'interruptions': interruptions,
      if (interruptionNotes != null) 'interruption_notes': interruptionNotes,
    });
  }
}

class ReportsApiClient {
  static final ApiClient _client = ApiClient.instance;

  static Future<ApiResponse<Map<String, dynamic>>> generateReport({
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    String? format,
  }) {
    return _client.post(ApiConstants.generateReport, data: {
      'type': type,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      if (format != null) 'format': format,
    });
  }

  static Future<ApiResponse<List<Map<String, dynamic>>>> getReports({
    int page = 1,
    int limit = 20,
    String? type,
    String? period,
  }) {
    return _client.get(ApiConstants.getReports, queryParameters: {
      'page': page,
      'limit': limit,
      if (type != null) 'type': type,
      if (period != null) 'period': period,
    });
  }

  static Future<ApiResponse<Map<String, dynamic>>> exportReport(String id, String format) {
    return _client.post(ApiConstants.exportReport(id), data: {
      'format': format,
    });
  }
}

class SyncApiClient {
  static final ApiClient _client = ApiClient.instance;

  static Future<ApiResponse<Map<String, dynamic>>> syncData(Map<String, dynamic> syncData) {
    return _client.post(ApiConstants.syncData, data: syncData);
  }

  static Future<ApiResponse<Map<String, dynamic>>> getSyncStatus() {
    return _client.get(ApiConstants.syncStatus);
  }

  static Future<ApiResponse<List<Map<String, dynamic>>>> getSyncConflicts() {
    return _client.get(ApiConstants.syncConflicts);
  }
}