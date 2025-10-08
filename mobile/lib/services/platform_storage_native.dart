// Native implementation using shared_preferences
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'platform_storage.dart';

PlatformStorage getPlatformStorage() => NativeStorage();

class NativeStorage implements PlatformStorage {
  static SharedPreferences? _prefs;
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get _storage {
    if (_prefs == null) {
      throw StateError('NativeStorage not initialized. Call NativeStorage.init() first.');
    }
    return _prefs!;
  }

  @override
  String? getItem(String key) => _storage.getString(key);

  @override
  void setItem(String key, String value) => _storage.setString(key, value);

  @override
  void removeItem(String key) => _storage.remove(key);

  @override
  void clear() => _storage.clear();

  @override
  List<String> get keys => _storage.getKeys().toList();
}
