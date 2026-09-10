/// OfflineRepository<T>
///
/// Generic offline-first data layer.
///
/// Usage pattern (in any feature repository):
///
///   final repo = OfflineRepository<List<Product>>(
///     db         : LocalDatabase.instance,
///     collection : 'stock',
///     key        : 'list',
///     fromJson   : (j) => (j as List).map(Product.fromJson).toList(),
///     toJson     : (v) => v.map((p) => p.toJson()).toList(),
///     fetch      : () => apiService.getStock(),
///     ttlSeconds : 300,   // 5-minute cache freshness
///   );
///
///   // In a Riverpod notifier:
///   Stream<OfflineResult<List<Product>>> stream = repo.stream();
///   // → emits OfflineResult.cached(stale data) immediately if cached,
///   //   then OfflineResult.fresh(new data) after the API call succeeds.
///
/// ─── OfflineResult ───────────────────────────────────────────────────────
///
///   .cached  — data came from local DB (may be stale)
///   .fresh   — data came from API + DB was updated
///   .error   — fetch failed; cached data (if any) is in `.cached`

import 'package:flutter/foundation.dart';
import 'package:dukaapp/core/database/local_database.dart';

// ── Result type ───────────────────────────────────────────────────────────────

enum OfflineSource { cached, fresh }

class OfflineResult<T> {
  const OfflineResult._({
    required this.data,
    required this.source,
    this.error,
    this.updatedAt,
  });

  factory OfflineResult.cached(T data, {DateTime? updatedAt}) =>
      OfflineResult._(data: data, source: OfflineSource.cached, updatedAt: updatedAt);

  factory OfflineResult.fresh(T data) =>
      OfflineResult._(data: data, source: OfflineSource.fresh, updatedAt: DateTime.now());

  factory OfflineResult.error(Object error, {T? cached}) =>
      OfflineResult._(data: cached, source: OfflineSource.cached, error: error);

  /// The data value; may be null when source==cached and nothing is stored yet.
  final T? data;
  final OfflineSource source;
  final Object? error;
  final DateTime? updatedAt;

  bool get isCached => source == OfflineSource.cached;
  bool get isFresh  => source == OfflineSource.fresh;
  bool get hasError => error != null;
  bool get hasData  => data != null;
}

// ── OfflineRepository ─────────────────────────────────────────────────────────

class OfflineRepository<T> {
  OfflineRepository({
    required LocalDatabase db,
    required this.collection,
    required this.key,
    required this.fromJson,
    required this.toJson,
    required this.fetch,
    this.ttlSeconds = 300,
  }) : _db = db;

  final LocalDatabase _db;

  /// Collection namespace in the local DB (e.g. 'dashboard', 'stock').
  final String collection;

  /// Row key within the collection (e.g. 'list', 'summary', or a record ID).
  final String key;

  /// Deserialise raw JSON from DB into [T].
  final T Function(dynamic json) fromJson;

  /// Serialise [T] back to JSON for storage.
  final dynamic Function(T value) toJson;

  /// The async function that fetches fresh data from the API.
  /// Must return the raw parsed data (List or Map).
  final Future<dynamic> Function() fetch;

  /// How long a cached entry is considered fresh (default 5 min).
  /// After this window the background fetch is always triggered.
  final int ttlSeconds;

  // ── Stream: offline-first ─────────────────────────────────────────────────

  /// Emits up to 2 events:
  ///   1. [OfflineResult.cached] if anything is in the DB (immediately)
  ///   2. [OfflineResult.fresh]  after the API fetch succeeds
  ///      — or [OfflineResult.error] if the fetch fails.
  Stream<OfflineResult<T>> stream() async* {
    // 1. Serve from cache
    T? cached = await _readCache();
    if (cached != null) {
      final ts = await _db.updatedAt(collection, key);
      final updatedAt = ts != null
          ? DateTime.fromMillisecondsSinceEpoch(ts)
          : null;
      yield OfflineResult.cached(cached, updatedAt: updatedAt);
    }

    // 2. Always try to refresh (caller decides whether to show stale or not)
    try {
      final raw  = await fetch();
      final data = fromJson(raw);
      await _writeCache(data);
      yield OfflineResult.fresh(data);
    } catch (e, st) {
      _log('fetch error: $e\n$st');
      yield OfflineResult.error(e, cached: cached);
    }
  }

  // ── One-shot: get from cache, refresh in background ───────────────────────

  /// Returns cached data immediately (null if empty), then starts a background
  /// fetch. The [onUpdate] callback is called with fresh data when the fetch
  /// completes successfully.
  Future<T?> getWithBackgroundRefresh({
    required void Function(T fresh) onUpdate,
    void Function(Object error)? onError,
  }) async {
    final cached = await _readCache();

    // Background fetch — do not await
    () async {
      try {
        final raw  = await fetch();
        final data = fromJson(raw);
        await _writeCache(data);
        onUpdate(data);
      } catch (e) {
        _log('background fetch error: $e');
        onError?.call(e);
      }
    }();

    return cached;
  }

  // ── Explicit refresh ──────────────────────────────────────────────────────

  /// Force a fresh fetch, update the cache, and return the new value.
  Future<T> refresh() async {
    final raw  = await fetch();
    final data = fromJson(raw);
    await _writeCache(data);
    return data;
  }

  // ── Cache helpers ─────────────────────────────────────────────────────────

  Future<T?> _readCache() async {
    if (!_db.isOpen) return null;
    try {
      final raw = await _db.get(collection, key);
      if (raw == null) return null;
      return fromJson(raw);
    } catch (e) {
      _log('cache read error: $e');
      return null;
    }
  }

  Future<void> _writeCache(T value) async {
    if (!_db.isOpen) return;
    try {
      await _db.put(collection, key, toJson(value));
    } catch (e) {
      _log('cache write error: $e');
    }
  }

  void _log(String msg) {
    if (kDebugMode) debugPrint('[OfflineRepo:$collection/$key] $msg');
  }
}
