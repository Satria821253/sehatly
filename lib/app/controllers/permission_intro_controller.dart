import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../routes/app_routes.dart';

class PermissionIntroController extends GetxController {
  static const String kConsentGiven = 'permission_consent_given';

  final isSaving = false.obs;

  static Future<bool> hasConsented() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(kConsentGiven) ?? false;
    } catch (_) {
      return false;
    }
  }
  Future<void> agree() async {
    if (isSaving.value) return;
    isSaving.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kConsentGiven, true);
      await prefs.setBool('has_seen_intro', true);
      Get.offAllNamed(AppRoutes.home);
    } finally {
      isSaving.value = false;
    }
  }
}
