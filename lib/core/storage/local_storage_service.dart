import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<SharedPreferences> get prefs async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
    return _prefs!;
  }

  SharedPreferences get syncPrefs {
    assert(_prefs != null, 'LocalStorageService must be initialized with init() first or use async prefs.');
    return _prefs!;
  }

  Future<void> saveString(String key, String value) async {
    final p = await prefs;
    await p.setString(key, value);
  }

  Future<String?> getString(String key) async {
    final p = await prefs;
    return p.getString(key);
  }

  Future<void> saveBool(String key, bool value) async {
    final p = await prefs;
    await p.setBool(key, value);
  }

  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final p = await prefs;
    return p.getBool(key) ?? defaultValue;
  }

  Future<void> saveInt(String key, int value) async {
    final p = await prefs;
    await p.setInt(key, value);
  }

  Future<int> getInt(String key, {int defaultValue = 0}) async {
    final p = await prefs;
    return p.getInt(key) ?? defaultValue;
  }

  Future<void> saveDouble(String key, double value) async {
    final p = await prefs;
    await p.setDouble(key, value);
  }

  Future<double> getDouble(String key, {double defaultValue = 0.0}) async {
    final p = await prefs;
    return p.getDouble(key) ?? defaultValue;
  }

  Future<void> remove(String key) async {
    final p = await prefs;
    await p.remove(key);
  }

  Future<void> clear() async {
    final p = await prefs;
    await p.clear();
  }

  Future<bool> containsKey(String key) async {
    final p = await prefs;
    return p.containsKey(key);
  }

  // Cache with TTL
  static const _cacheTimestampPrefix = '_cache_timestamp_';

  Future<void> cacheWithTTL(String key, String value, Duration ttl) async {
    await saveString(key, value);
    await saveString(
      '$_cacheTimestampPrefix$key',
      DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  Future<String?> getCachedValue(String key, {Duration? ttl}) async {
    final p = await prefs;
    if (!p.containsKey(key)) return null;

    if (ttl != null) {
      final timestampStr = p.getString('$_cacheTimestampPrefix$key');
      if (timestampStr != null) {
        final timestamp = int.tryParse(timestampStr);
        if (timestamp != null) {
          final cachedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
          if (DateTime.now().difference(cachedAt) > ttl) {
            return null;
          }
        }
      }
    }

    return p.getString(key);
  }

  Future<void> removeCache(String key) async {
    await remove(key);
    await remove('$_cacheTimestampPrefix$key');
  }
}
