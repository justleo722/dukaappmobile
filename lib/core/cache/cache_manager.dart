import 'dart:async';
import 'package:dukaapp/core/storage/local_storage_service.dart';

class CacheManager {
  final LocalStorageService _localStorage;
  final Map<String, Completer<dynamic>> _pendingRequests = {};

  CacheManager({required LocalStorageService localStorage})
      : _localStorage = localStorage;

  Future<T?> get<T>({
    required String key,
    required Future<T?> Function() fetcher,
    Duration? ttl,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _localStorage.getCachedValue(key, ttl: ttl);
      if (cached != null) {
        return cached as T;
      }
    }

    if (_pendingRequests.containsKey(key)) {
      return await _pendingRequests[key]!.future as T?;
    }

    final completer = Completer<dynamic>();
    _pendingRequests[key] = completer;

    try {
      final result = await fetcher();
      if (result != null) {
        await _localStorage.cacheWithTTL(
          key,
          result.toString(),
          ttl ?? const Duration(hours: 24),
        );
      }
      completer.complete(result);
      return result;
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      _pendingRequests.remove(key);
    }
  }

  Future<void> invalidate(String key) async {
    await _localStorage.removeCache(key);
  }

  Future<void> invalidateAll(List<String> keys) async {
    for (final key in keys) {
      await invalidate(key);
    }
  }

  Future<bool> isCached(String key, {Duration? ttl}) async {
    final cached = await _localStorage.getCachedValue(key, ttl: ttl);
    return cached != null;
  }
}
