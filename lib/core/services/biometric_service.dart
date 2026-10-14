import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static final _auth = LocalAuthentication();
  static const _kEnabled = 'biometric_enabled';
  static const _kSavedId = 'biometric_saved_id';
  static const _kSavedPw = 'biometric_saved_pw';

  // Login details for biometric re-login live in encrypted storage, never in
  // plain SharedPreferences.
  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );

  /// Why the last [authenticate] call failed, for showing to the user; empty
  /// when it succeeded or the user cancelled.
  static String lastError = '';

  static Future<bool> isAvailable() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      if (!isSupported) return false;
      // canCheckBiometrics returns false on some devices even when fingerprints
      // are enrolled — fall back to getAvailableBiometrics() as a second check.
      final canCheck = await _auth.canCheckBiometrics;
      if (canCheck) return true;
      final available = await _auth.getAvailableBiometrics();
      return available.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kEnabled) ?? false;
  }

  static Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, value);
  }

  static Future<bool> authenticate() async {
    lastError = '';
    try {
      return await _auth.authenticate(
        localizedReason: 'Ingia kwa kutumia kidole au uso wako',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } on PlatformException catch (e) {
      lastError = switch (e.code) {
        auth_error.notEnrolled => 'Hakuna kidole/uso uliosajiliwa kwenye simu. Ongeza kwenye Settings za simu.',
        auth_error.passcodeNotSet => 'Weka kwanza screen lock (PIN, pattern au password) kwenye simu.',
        auth_error.notAvailable => 'Biometric haipatikani kwenye simu hii.',
        auth_error.lockedOut => 'Umejaribu mara nyingi. Subiri kidogo kisha ujaribu tena.',
        auth_error.permanentlyLockedOut => 'Biometric imefungwa. Fungua simu kwa PIN kisha ujaribu tena.',
        _ => 'Biometric imeshindikana: ${e.message ?? e.code}',
      };
      return false;
    } catch (e) {
      lastError = 'Biometric imeshindikana: $e';
      return false;
    }
  }

  static Future<void> saveCredentials(String id, String password) async {
    await _secure.write(key: _kSavedId, value: id);
    await _secure.write(key: _kSavedPw, value: password);
  }

  /// Saved login details, or null. Moves details saved by older versions out of
  /// plain SharedPreferences.
  static Future<({String id, String password})?> readCredentials() async {
    var id = await _secure.read(key: _kSavedId) ?? '';
    var pw = await _secure.read(key: _kSavedPw) ?? '';
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_kSavedId) || prefs.containsKey(_kSavedPw)) {
      if (id.isEmpty || pw.isEmpty) {
        id = prefs.getString(_kSavedId) ?? '';
        pw = prefs.getString(_kSavedPw) ?? '';
        if (id.isNotEmpty && pw.isNotEmpty) await saveCredentials(id, pw);
      }
      await prefs.remove(_kSavedId);
      await prefs.remove(_kSavedPw);
    }
    if (id.isEmpty || pw.isEmpty) return null;
    return (id: id, password: pw);
  }
}
