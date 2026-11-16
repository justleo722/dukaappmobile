import 'dart:convert';

import 'package:flutter/services.dart';

/// A country of the register form (assets/l10n/countries.json, copied from the
/// backend's application/data/countries.json by tool/sync_l10n.py).
class Country {
  final String iso;
  final String name;
  final String dial;

  /// Digits after the dial code when the length is fixed (null = 6–12).
  final int? len;

  const Country({required this.iso, required this.name, required this.dial, this.len});

  static const tanzania = Country(iso: 'TZ', name: 'Tanzania', dial: '255', len: 9);

  static List<Country> all = const [tanzania];

  static Future<void> load() async {
    try {
      final rows = jsonDecode(await rootBundle.loadString('assets/l10n/countries.json')) as List;
      final list = rows
          .whereType<Map>()
          .map((m) => Country(
                iso: '${m['iso']}'.toUpperCase(),
                name: '${m['name']}',
                dial: '${m['dial']}',
                len: m['len'] is int ? m['len'] as int : int.tryParse('${m['len'] ?? ''}'),
              ))
          .where((c) => c.iso.length == 2 && c.dial.isNotEmpty)
          .toList();
      if (list.isNotEmpty) all = list;
    } catch (_) {
      // Keep Tanzania only.
    }
  }

  /// The country with this ISO code, or null.
  static Country? byIso(String? iso) {
    final code = (iso ?? '').toUpperCase();
    for (final c in all) {
      if (c.iso == code) return c;
    }
    return null;
  }

  /// "🇹🇿" from the ISO code.
  String get flag => iso.length == 2
      ? String.fromCharCodes(iso.codeUnits.map((u) => 0x1F1E6 + u - 0x41))
      : '';
}
