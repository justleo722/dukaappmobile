import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

const _packageId = 'com.dukaapp.app';
const _marketUrl = 'market://details?id=$_packageId';
const _storeUrl  = 'https://play.google.com/store/apps/details?id=$_packageId&hl=en';

class UpdateService {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  /// Scrapes the Play Store listing page for the latest version name.
  /// Returns null if unreachable or parsing fails.
  Future<String?> _fetchStoreVersion() async {
    try {
      final res = await Dio().get(
        _storeUrl,
        options: Options(
          headers: {'User-Agent': 'Mozilla/5.0'},
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      final body = res.data as String? ?? '';
      final match = RegExp(r'\[\[\["(\d+\.\d+[\.\d]*)"\]\]').firstMatch(body);
      return match?.group(1);
    } catch (_) {
      return null;
    }
  }

  /// Converts a version string like "1.2.3" into a comparable integer
  /// by treating each segment as a 3-digit padded number: 001002003.
  int _versionToInt(String v) {
    final parts = v.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    var result = 0;
    for (final p in parts) {
      result = result * 1000 + p;
    }
    return result;
  }

  Future<void> _openPlayStore() async {
    final market = Uri.parse(_marketUrl);
    if (await canLaunchUrl(market)) {
      await launchUrl(market, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(Uri.parse(_storeUrl), mode: LaunchMode.externalApplication);
    }
  }

  /// Checks Play Store and shows an update dialog if a newer version exists.
  /// Reads the installed build number automatically — no manual version string needed.
  Future<void> checkAndPrompt(BuildContext context) async {
    final info = await PackageInfo.fromPlatform();
    final currentBuild = int.tryParse(info.buildNumber) ?? 0;
    final currentVersion = info.version; // e.g. "1.0.0"

    final storeVersion = await _fetchStoreVersion();
    if (storeVersion == null) return;

    final storeInt   = _versionToInt(storeVersion);
    final currentInt = _versionToInt(currentVersion);

    // Update available only when store version is strictly greater
    if (storeInt <= currentInt) return;

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Update Available',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        content: Text(
          'DukaApp v$storeVersion is available (you have v$currentVersion build $currentBuild).\nUpdate now for the latest features and fixes.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Later', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _openPlayStore();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Update Now',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
