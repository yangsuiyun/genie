// Platform-agnostic storage abstraction
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'platform_storage_stub.dart'
    if (dart.library.html) 'platform_storage_web.dart'
    if (dart.library.io) 'platform_storage_native.dart';

/// Platform-independent storage interface
abstract class PlatformStorage {
  factory PlatformStorage() => getPlatformStorage();

  String? getItem(String key);
  void setItem(String key, String value);
  void removeItem(String key);
  void clear();
  List<String> get keys;
}

/// Helper methods for common operations
extension PlatformStorageExtensions on PlatformStorage {
  T? getJson<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    final value = getItem(key);
    if (value == null) return null;
    try {
      return fromJson(json.decode(value));
    } catch (e) {
      return null;
    }
  }

  void setJson<T>(String key, T value, Map<String, dynamic> Function(T) toJson) {
    setItem(key, json.encode(toJson(value)));
  }

  List<T> getJsonList<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    final value = getItem(key);
    if (value == null) return [];
    try {
      final List<dynamic> list = json.decode(value);
      return list.map((item) => fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  void setJsonList<T>(String key, List<T> list, Map<String, dynamic> Function(T) toJson) {
    setItem(key, json.encode(list.map(toJson).toList()));
  }
}
