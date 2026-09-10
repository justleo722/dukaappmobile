/// DatabaseService
///
/// Thin wrapper that features use to read/write the local DB without
/// importing [LocalDatabase] directly.  Keeps the API surface small.

import 'package:dukaapp/core/database/local_database.dart';
import 'package:dukaapp/core/database/offline_repository.dart';

class DatabaseService {
  const DatabaseService(this._db);
  final LocalDatabase _db;

  bool    get isOpen     => _db.isOpen;
  bool    get isPublic   => _db.isPublic;
  bool    get isPrivate  => _db.isPrivate;
  String? get currentDb  => _db.currentDbName;

  /// Open the public DB for [shopId] (no login required).
  /// Used by the online-shop / catalogue screens.
  Future<void> openPublic(String shopId) => _db.openPublic(shopId);

  // ── Low-level ─────────────────────────────────────────────────────────────

  Future<dynamic> get(String collection, String key) =>
      _db.get(collection, key);

  Future<List<dynamic>> getAll(String collection) =>
      _db.getAll(collection);

  Future<void> put(String collection, String key, dynamic value,
          {int? ttlSeconds}) =>
      _db.put(collection, key, value, ttlSeconds: ttlSeconds);

  Future<void> delete(String collection, String key) =>
      _db.delete(collection, key);

  Future<void> deleteCollection(String collection) =>
      _db.deleteCollection(collection);

  Future<void> clearAll() => _db.clearAll();

  Future<int?> updatedAt(String collection, String key) =>
      _db.updatedAt(collection, key);

  // ── High-level: build an offline repo for any feature ─────────────────────

  /// Create an [OfflineRepository] for [T] with typed serialisation.
  ///
  /// Example:
  /// ```dart
  /// final repo = db.repository<List<Product>>(
  ///   collection : 'stock',
  ///   key        : 'list',
  ///   fromJson   : (j) => (j as List).map(Product.fromJson).toList(),
  ///   toJson     : (v) => v.map((e) => e.toJson()).toList(),
  ///   fetch      : () async {
  ///     final res = await apiService.getStock();
  ///     return res.data as List;
  ///   },
  /// );
  /// ```
  OfflineRepository<T> repository<T>({
    required String collection,
    required String key,
    required T Function(dynamic) fromJson,
    required dynamic Function(T) toJson,
    required Future<dynamic> Function() fetch,
    int ttlSeconds = 300,
  }) {
    return OfflineRepository<T>(
      db         : _db,
      collection : collection,
      key        : key,
      fromJson   : fromJson,
      toJson     : toJson,
      fetch      : fetch,
      ttlSeconds : ttlSeconds,
    );
  }
}
