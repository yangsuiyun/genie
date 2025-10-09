// API响应模型
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int? statusCode;
  final Map<String, dynamic>? headers;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.statusCode,
    this.headers,
  });

  factory ApiResponse.success(T data, {int? statusCode, Map<String, dynamic>? headers}) {
    return ApiResponse<T>(
      success: true,
      data: data,
      statusCode: statusCode,
      headers: headers,
    );
  }

  factory ApiResponse.error(String error, {int? statusCode, Map<String, dynamic>? headers}) {
    return ApiResponse<T>(
      success: false,
      error: error,
      statusCode: statusCode,
      headers: headers,
    );
  }

  bool get isSuccess => success;
  bool get isError => !success;

  @override
  String toString() {
    return 'ApiResponse(success: $success, data: $data, error: $error, statusCode: $statusCode)';
  }
}
