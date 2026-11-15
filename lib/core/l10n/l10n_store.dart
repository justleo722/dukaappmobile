import 'dart:convert';

import 'package:flutter/services.dart';

/// The app's local language files (assets/l10n/<code>.json, written from the
/// shared registry by tool/sync_l10n.py). Loaded once at startup; the app
/// translates offline.
class L10nStore {
  L10nStore._();

  static final Map<String, Map<String, String>> _texts = {};

  /// Languages the app ships, code → name (from assets/l10n/languages.json).
  static Map<String, String> languages = const {'en': 'English', 'sw': 'Kiswahili'};

  static Future<void> load() async {
    try {
      final manifest = jsonDecode(await rootBundle.loadString('assets/l10n/languages.json')) as Map<String, dynamic>;
      final list = (manifest['languages'] as Map?)?.map((k, v) => MapEntry('$k', '$v'));
      if (list != null && list.isNotEmpty) languages = Map<String, String>.from(list);
    } catch (_) {
      // Keep the defaults.
    }
    for (final code in languages.keys) {
      try {
        final data = jsonDecode(await rootBundle.loadString('assets/l10n/$code.json')) as Map<String, dynamic>;
        _texts[code] = data.map((k, v) => MapEntry(k, '$v'));
      } catch (_) {
        // A missing file falls back to the built-in English texts.
      }
    }
  }

  /// key → text for [code] (empty when not loaded: callers fall back to English).
  static Map<String, String> textsFor(String code) => _texts[code] ?? const {};
}
