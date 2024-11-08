import 'dart:async';

class CacheEntry<T> {
  final T data;
  final DateTime timestamp;

  CacheEntry(this.data, this.timestamp);

  bool isExpired(Duration timeout) {
    return DateTime.now().difference(timestamp) > timeout;
  }
}

class CacheManager {
  final Map<String, CacheEntry<dynamic>> _cache = {};
  final Duration defaultTimeout;

  CacheManager({this.defaultTimeout = const Duration(minutes: 5)});

  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null || entry.isExpired(defaultTimeout)) {
      _cache.remove(key);
      return null;
    }
    return entry.data as T;
  }

  void set<T>(String key, T data) {
    _cache[key] = CacheEntry<T>(data, DateTime.now());
  }

  void remove(String key) {
    _cache.remove(key);
  }

  void clear() {
    _cache.clear();
  }

  bool hasValid(String key) {
    final entry = _cache[key];
    return entry != null && !entry.isExpired(defaultTimeout);
  }
  
  List<String> getKeys() {
    return _cache.keys.toList();
  }
}