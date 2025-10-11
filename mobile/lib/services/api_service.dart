import 'dart:convert';
import 'package:http/http.dart' as http;

/// API服务类 - 处理所有后端API调用
class ApiService {
  // 后端API基础URL
  static const String baseUrl = 'http://localhost:8081/api';
  
  // HTTP客户端
  final http.Client _client;
  
  // 认证Token（如果需要）
  String? _authToken;
  
  ApiService({http.Client? client}) : _client = client ?? http.Client();
  
  /// 设置认证Token
  void setAuthToken(String token) {
    _authToken = token;
  }
  
  /// 获取通用请求头
  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
    };
    
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    
    return headers;
  }
  
  // ==================== 项目相关API ====================
  
  /// 获取所有项目
  Future<List<Map<String, dynamic>>> getProjects() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/projects'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw ApiException('获取项目列表失败', response.statusCode);
      }
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// 创建项目
  Future<Map<String, dynamic>> createProject(Map<String, dynamic> project) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/projects'),
        headers: _getHeaders(),
        body: jsonEncode(project),
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw ApiException('创建项目失败', response.statusCode);
      }
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// 更新项目
  Future<Map<String, dynamic>> updateProject(String id, Map<String, dynamic> project) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/projects/$id'),
        headers: _getHeaders(),
        body: jsonEncode(project),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw ApiException('更新项目失败', response.statusCode);
      }
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// 删除项目
  Future<void> deleteProject(String id) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/projects/$id'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ApiException('删除项目失败', response.statusCode);
      }
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  // ==================== 任务相关API ====================
  
  /// 获取所有任务（可选按项目过滤）
  Future<List<Map<String, dynamic>>> getTasks({String? projectId}) async {
    try {
      String url = '$baseUrl/tasks';
      if (projectId != null) {
        url += '?project_id=$projectId';
      }
      
      final response = await _client.get(
        Uri.parse(url),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw ApiException('获取任务列表失败', response.statusCode);
      }
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// 创建任务
  Future<Map<String, dynamic>> createTask(Map<String, dynamic> task) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/tasks'),
        headers: _getHeaders(),
        body: jsonEncode(task),
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw ApiException('创建任务失败', response.statusCode);
      }
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// 更新任务
  Future<Map<String, dynamic>> updateTask(String id, Map<String, dynamic> task) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/tasks/$id'),
        headers: _getHeaders(),
        body: jsonEncode(task),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw ApiException('更新任务失败', response.statusCode);
      }
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// 删除任务
  Future<void> deleteTask(String id) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/tasks/$id'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ApiException('删除任务失败', response.statusCode);
      }
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  // ==================== 番茄钟相关API ====================
  
  /// 开始番茄钟会话
  Future<Map<String, dynamic>> startPomodoroSession(String taskId) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/pomodoro/start'),
        headers: _getHeaders(),
        body: jsonEncode({
          'task_id': taskId,
        }),
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw ApiException('开始番茄钟失败', response.statusCode);
      }
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// 完成番茄钟会话
  Future<Map<String, dynamic>> completePomodoroSession(
    String sessionId,
    int duration,
  ) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/pomodoro/complete'),
        headers: _getHeaders(),
        body: jsonEncode({
          'session_id': sessionId,
          'duration': duration,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw ApiException('完成番茄钟失败', response.statusCode);
      }
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// 获取番茄钟统计
  Future<Map<String, dynamic>> getPomodoroStats({
    String? taskId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      String url = '$baseUrl/pomodoro/stats';
      final params = <String>[];
      
      if (taskId != null) params.add('task_id=$taskId');
      if (startDate != null) params.add('start_date=${startDate.toIso8601String()}');
      if (endDate != null) params.add('end_date=${endDate.toIso8601String()}');
      
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }
      
      final response = await _client.get(
        Uri.parse(url),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw ApiException('获取统计数据失败', response.statusCode);
      }
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  // ==================== 错误处理 ====================
  
  Exception _handleError(dynamic error) {
    if (error is ApiException) {
      return error;
    }
    
    if (error is http.ClientException) {
      return NetworkException('网络连接失败，请检查网络设置');
    }
    
    if (error is FormatException) {
      return ApiException('数据格式错误', 0);
    }
    
    return ApiException('未知错误: ${error.toString()}', 0);
  }
  
  /// 关闭HTTP客户端
  void dispose() {
    _client.close();
  }
}

// ==================== 异常类定义 ====================

/// API异常基类
class ApiException implements Exception {
  final String message;
  final int statusCode;
  
  ApiException(this.message, this.statusCode);
  
  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
  
  bool get isNotFound => statusCode == 404;
  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isServerError => statusCode >= 500;
}

/// 网络异常
class NetworkException implements Exception {
  final String message;
  
  NetworkException(this.message);
  
  @override
  String toString() => 'NetworkException: $message';
}

// ==================== 单例模式 ====================

/// 全局API服务实例
final apiService = ApiService();

