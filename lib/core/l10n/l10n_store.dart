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

  /// Current app language, kept in sync by LocaleNotifier.
  static String current = 'en';

  static final Map<String, Map<String, String>> _fromEnglish = {};

  /// An English registry text in [code] (default: the current language);
  /// unchanged when the registry doesn't have it.
  static String fromEnglish(String english, [String? code]) {
    final lang = code ?? current;
    if (lang == 'en') return english;
    final map = _fromEnglish.putIfAbsent(lang, () {
      final en = _texts['en'] ?? const {};
      final to = _texts[lang] ?? const {};
      final out = <String, String>{};
      en.forEach((key, text) {
        final t = to[key];
        if (t != null && t.isNotEmpty) out.putIfAbsent(text, () => t);
      });
      return out;
    });
    return map[english] ?? english;
  }

  /// key → text for [code] (empty when not loaded: callers fall back to English).
  static Map<String, String> textsFor(String code) => _texts[code] ?? const {};
}
