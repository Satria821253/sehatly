import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
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
    final route = await LocationPermissionController.nextRoute();
    debugPrint('>>> goHome: nextRoute=$route, current=${Get.currentRoute}');
    if (Get.currentRoute != AppRoutes.splash) return;
    Get.offAllNamed(route);
  }
}
