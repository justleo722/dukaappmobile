import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;
  SharedPreferences? _prefs;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  static const _tokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _sessionKey = 'session_data';
  static const _userKey = 'user_data';
  static const _shopKey = 'active_shop_data';
  static const _permissionsKey = 'permissions_data';

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (_) {}
    final prefs = await _getPrefs();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token != null && token.isNotEmpty) return token;
    } catch (_) {}
    final prefs = await _getPrefs();
    return prefs.getString(_tokenKey);
  }

  Future<void> saveRefreshToken(String token) async {
    try {
      await _storage.write(key: _refreshTokenKey, value: token);
    } catch (_) {}
    final prefs = await _getPrefs();
    await prefs.setString(_refreshTokenKey, token);
  }

  Future<String?> getRefreshToken() async {
    try {
      final token = await _storage.read(key: _refreshTokenKey);
      if (token != null && token.isNotEmpty) return token;
    } catch (_) {}
    final prefs = await _getPrefs();
    return prefs.getString(_refreshTokenKey);
  }

  Future<void> saveSession(Map<String, dynamic> session) async {
    final encoded = jsonEncode(session);
    try {
      await _storage.write(key: _sessionKey, value: encoded);
    } catch (_) {}
    final prefs = await _getPrefs();
    await prefs.setString(_sessionKey, encoded);
  }

  Future<Map<String, dynamic>?> getSession() async {
    String? data;
    try {
      data = await _storage.read(key: _sessionKey);
    } catch (_) {}
    data ??= (await _getPrefs()).getString(_sessionKey);
    if (data == null) return null;
    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    final encoded = jsonEncode(user);
    try {
      await _storage.write(key: _userKey, value: encoded);
    } catch (_) {}
    final prefs = await _getPrefs();
    await prefs.setString(_userKey, encoded);
  }

  Future<Map<String, dynamic>?> getUser() async {
    String? data;
    try {
      data = await _storage.read(key: _userKey);
    } catch (_) {}
    data ??= (await _getPrefs()).getString(_userKey);
    if (data == null) return null;
    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveActiveShop(Map<String, dynamic> shop) async {
    final encoded = jsonEncode(shop);
    try {
      await _storage.write(key: _shopKey, value: encoded);
    } catch (_) {}
    final prefs = await _getPrefs();
    await prefs.setString(_shopKey, encoded);
  }

  Future<Map<String, dynamic>?> getActiveShop() async {
    String? data;
    try {
      data = await _storage.read(key: _shopKey);
    } catch (_) {}
    data ??= (await _getPrefs()).getString(_shopKey);
    if (data == null) return null;
    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> savePermissions(Map<String, dynamic> permissions) async {
    final encoded = jsonEncode(permissions);
    try {
      await _storage.write(key: _permissionsKey, value: encoded);
    } catch (_) {}
    final prefs = await _getPrefs();
    await prefs.setString(_permissionsKey, encoded);
  }

  Future<Map<String, dynamic>?> getPermissions() async {
    String? data;
    try {
      data = await _storage.read(key: _permissionsKey);
    } catch (_) {}
    data ??= (await _getPrefs()).getString(_permissionsKey);
    if (data == null) return null;
    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (_) {}
    final prefs = await _getPrefs();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_sessionKey);
    await prefs.remove(_userKey);
    await prefs.remove(_shopKey);
    await prefs.remove(_permissionsKey);
  }

  Future<void> clearAuthData() async {
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _refreshTokenKey);
      await _storage.delete(key: _sessionKey);
      await _storage.delete(key: _userKey);
      await _storage.delete(key: _shopKey);
      await _storage.delete(key: _permissionsKey);
    } catch (_) {}
    final prefs = await _getPrefs();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_sessionKey);
    await prefs.remove(_userKey);
    await prefs.remove(_shopKey);
    await prefs.remove(_permissionsKey);
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
