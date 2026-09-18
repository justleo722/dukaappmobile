import 'package:in_app_update/in_app_update.dart';

class AppUpdateService {
  AppUpdateService._();

  /// Call once on app launch. Silently checks Play Store for a pending update
  /// and triggers a flexible update flow if one is available.
  static Future<void> checkForUpdate() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        await InAppUpdate.startFlexibleUpdate();
        await InAppUpdate.completeFlexibleUpdate();
      }
    } catch (_) {
      // Not on Play Store (debug/local build) — ignore silently
    }
  }
}
