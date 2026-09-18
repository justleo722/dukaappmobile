import 'dart:convert';
import 'package:dukaapp/core/database/database_service.dart';

/// Simple key-value cache backed by DatabaseService (SQLite per shop).
/// Used by feature pages to serve stale data while the API loads.
class LocalCacheService {
  final DatabaseService _db;
  const LocalCacheService(this._db);

  /// Save [data] (List or Map) under [collection]/[key].
  Future<void> save(String collection, String key, dynamic data, {int ttlSeconds = 3600}) async {
    if (!_db.isOpen) return;
    try {
      await _db.put(collection, key, data, ttlSeconds: ttlSeconds);
    } catch (_) {}
  }

  /// Load a List of Maps. Returns [] if no cache or DB not open.
  Future<List<Map<String, dynamic>>> loadList(String collection, String key) async {
    if (!_db.isOpen) return [];
    try {
      final raw = await _db.get(collection, key);
      if (raw == null) return [];
      if (raw is List) return raw.whereType<Map<String, dynamic>>().toList();
      if (raw is String) {
        final decoded = jsonDecode(raw);
        if (decoded is List) return decoded.whereType<Map<String, dynamic>>().toList();
      }
    } catch (_) {}
    return [];
  }

  /// Load a Map. Returns {} if no cache or DB not open.
  Future<Map<String, dynamic>> loadMap(String collection, String key) async {
    if (!_db.isOpen) return {};
    try {
      final raw = await _db.get(collection, key);
      if (raw == null) return {};
      if (raw is Map<String, dynamic>) return raw;
      if (raw is String) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
      }
    } catch (_) {}
    return {};
  }
}
