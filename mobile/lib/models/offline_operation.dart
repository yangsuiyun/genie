// 离线操作模型
enum OfflineOperationType {
  create,
  update,
  delete,
}

class OfflineOperation {
  final String id;
  final OfflineOperationType type;
  final String endpoint;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int retryCount;

  OfflineOperation({
    required this.id,
    required this.type,
    required this.endpoint,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
  });

  OfflineOperation copyWith({
    String? id,
    OfflineOperationType? type,
    String? endpoint,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    int? retryCount,
  }) {
    return OfflineOperation(
      id: id ?? this.id,
      type: type ?? this.type,
      endpoint: endpoint ?? this.endpoint,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'endpoint': endpoint,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'retryCount': retryCount,
    };
  }

  factory OfflineOperation.fromJson(Map<String, dynamic> json) {
    return OfflineOperation(
      id: json['id'],
      type: OfflineOperationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => OfflineOperationType.create,
      ),
      endpoint: json['endpoint'],
      data: Map<String, dynamic>.from(json['data']),
      timestamp: DateTime.parse(json['timestamp']),
      retryCount: json['retryCount'] ?? 0,
    );
  }

  @override
  String toString() {
    return 'OfflineOperation(id: $id, type: $type, endpoint: $endpoint, retryCount: $retryCount)';
  }
}
