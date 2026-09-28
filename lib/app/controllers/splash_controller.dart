import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/location_permission_controller.dart';
import '../routes/app_routes.dart';

class SplashController extends GetxController {
  static const Duration displayDuration = Duration(milliseconds: 3500);
  static const String _kHasOpened = 'has_reached_home';

  @override
  void onReady() {
    super.onReady();
    Future.delayed(displayDuration, goHome);
  }

  Future<void> goHome() async {
    debugPrint('>>> goHome: route=${Get.currentRoute}');
    if (Get.currentRoute != AppRoutes.splash) return;

    final prefs = await SharedPreferences.getInstance();
    final hasReachedHome = prefs.getBool(_kHasOpened) ?? false;
    final hasSeenIntro = prefs.getBool('has_seen_intro') ?? false;

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
