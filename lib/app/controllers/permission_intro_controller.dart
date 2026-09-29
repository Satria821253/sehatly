import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/prefs_keys.dart';
import '../routes/app_routes.dart';

class PermissionIntroController extends GetxController {
  final isSaving = false.obs;

  static Future<bool> hasConsented() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(PrefsKeys.permissionConsentGiven) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> agree() async {
    if (isSaving.value) return;
    isSaving.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(PrefsKeys.permissionConsentGiven, true);
      await prefs.setBool(PrefsKeys.hasSeenIntro, true);
      Get.offAllNamed(AppRoutes.home);
    } finally {
      isSaving.value = false;
    }
  }
}
