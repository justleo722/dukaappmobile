import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'package:dukaapp/app/app.dart' show showAppToast;
import 'package:dukaapp/core/config/api_config.dart';
import 'package:dukaapp/core/network/api_client.dart';

/// FCM push notifications.
///
/// The Firebase config comes from the server (Super Admin → System Credentials
/// → Push Notifications), so the app ships without google-services.json. After
/// every sign-in / shop switch the device token is linked to that user and
/// shop; on sign-out it is removed. Notification messages are shown by the
/// system while the app is in the background; in the foreground they show as
/// a toast. When push isn't set up on the server, everything here is a no-op.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  ApiClient? _api;
  bool _ready = false;
  StreamSubscription<String>? _refreshSub;
  StreamSubscription<RemoteMessage>? _messageSub;

  void attach(ApiClient api) => _api = api;

  String get _platform => Platform.isIOS ? 'ios' : 'android';

  /// Initialises Firebase with the server's config. False when push is off.
  Future<bool> _ensureFirebase() async {
    if (_ready) return true;
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return false;
    try {
      if (Firebase.apps.isEmpty) {
        final res = await Dio().get('${ApiConfig.appApiBase}/auth/push_config/$_platform');
        final cfg = (res.data is Map) ? res.data['config'] : null;
        if (cfg is! Map || (cfg['appId'] ?? '').toString().isEmpty) return false;
        await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: '${cfg['apiKey']}',
            appId: '${cfg['appId']}',
            messagingSenderId: '${cfg['messagingSenderId']}',
            projectId: '${cfg['projectId']}',
            storageBucket: cfg['storageBucket']?.toString(),
          ),
        );
      }
      _ready = true;
      return true;
    } catch (e) {
      debugPrint('[Push] setup skipped: $e');
      return false;
    }
  }

  /// Call after the auth token is saved (sign-in, register, shop switch, restore).
  Future<void> registerDevice() async {
    try {
      if (_api == null || !await _ensureFirebase()) return;
      final messaging = FirebaseMessaging.instance;
      final perm = await messaging.requestPermission();
      if (perm.authorizationStatus == AuthorizationStatus.denied) return;
      await messaging.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);

      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;
      await _send(token);

      _refreshSub ??= messaging.onTokenRefresh.listen(_send);
      _messageSub ??= FirebaseMessaging.onMessage.listen((m) {
        final n = m.notification;
        if (n == null) return;
        // Android shows nothing on its own while the app is open.
        if (Platform.isAndroid) {
          showAppToast([n.title, n.body].whereType<String>().where((s) => s.isNotEmpty).join(': '));
        }
      });
    } catch (e) {
      debugPrint('[Push] register failed: $e');
    }
  }

  Future<void> _send(String token) async {
    try {
      await _api?.post('${ApiConfig.appApiBase}/auth/push_register', data: {'token': token, 'platform': _platform});
    } catch (e) {
      debugPrint('[Push] token not saved: $e');
    }
  }

  /// Call before signing out so this device stops getting the shop's pushes.
  Future<void> unregisterDevice() async {
    if (!_ready) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _api?.post('${ApiConfig.appApiBase}/auth/push_unregister', data: {'token': token});
      }
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint('[Push] unregister failed: $e');
    }
  }
}
