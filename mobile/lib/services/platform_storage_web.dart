// Web implementation using dart:html
import 'dart:html' as html;
import 'platform_storage.dart';

PlatformStorage getPlatformStorage() => WebStorage();

class WebStorage implements PlatformStorage {
  final html.Storage _storage = html.window.localStorage;

  @override
  String? getItem(String key) => _storage[key];

  @override
  void setItem(String key, String value) => _storage[key] = value;

  @override
  void removeItem(String key) => _storage.remove(key);

  @override
  void clear() => _storage.clear();

  @override
  List<String> get keys => _storage.keys.toList();
}
