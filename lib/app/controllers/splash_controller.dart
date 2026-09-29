import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/prefs_keys.dart';
import '../controllers/location_permission_controller.dart';
import '../routes/app_routes.dart';

class SplashController extends GetxController {
  static const Duration displayDuration = Duration(milliseconds: 3500);

  @override
  void onReady() {
    super.onReady();
    Future.delayed(displayDuration, goHome);
  }

  Future<void> goHome() async {
    debugPrint('>>> goHome: route=${Get.currentRoute}');
    if (Get.currentRoute != AppRoutes.splash) return;

    final prefs = await SharedPreferences.getInstance();
    final hasReachedHome = prefs.getBool(PrefsKeys.hasReachedHome) ?? false;
    final hasSeenIntro = prefs.getBool(PrefsKeys.hasSeenIntro) ?? false;

    String route;
    if (!hasReachedHome) {
      route = await LocationPermissionController.nextRoute();
    } else if (!hasSeenIntro) {
      // Sudah pernah sampai home tapi belum lihat intro → tampilkan sekali
      route = AppRoutes.permissionIntro;
    } else {
      // Sudah lihat intro → langsung home
      route = AppRoutes.home;
    }

    debugPrint('>>> goHome: nextRoute=$route, current=${Get.currentRoute}');
    if (Get.currentRoute != AppRoutes.splash) return;
    Get.offAllNamed(route);
  }
}
