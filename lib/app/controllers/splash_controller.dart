import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/prefs_keys.dart';
import '../controllers/location_permission_controller.dart';
import '../routes/app_routes.dart';
import '../services/network_status.dart';

class SplashController extends GetxController {
  static const Duration displayDuration = Duration(milliseconds: 3500);

  @override
  void onReady() {
    super.onReady();
    Future.delayed(displayDuration, goHome);
  }

  /// Tentukan halaman tujuan setelah splash dari status penyimpanan
  /// (izin lokasi → intro → home). Dipakai bersama oleh [goHome] dan
  /// layar "Cek Jaringanmu" saat user menekan Coba Lagi.
  static Future<String> resolveNextRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final hasReachedHome = prefs.getBool(PrefsKeys.hasReachedHome) ?? false;
    final hasSeenIntro = prefs.getBool(PrefsKeys.hasSeenIntro) ?? false;

    if (!hasReachedHome) {
      return LocationPermissionController.nextRoute();
    }
    if (!hasSeenIntro) {
      // Sudah pernah sampai home tapi belum lihat intro → tampilkan sekali
      return AppRoutes.permissionIntro;
    }
    // Sudah lihat intro → langsung home
    return AppRoutes.home;
  }

  Future<void> goHome() async {
    if (Get.currentRoute != AppRoutes.splash) return;

    // Internet jelek/mati → tahan user di layar "Cek Jaringanmu"
    // (Lottie + tombol Coba Lagi), jangan masuk home dalam kondisi kosong.
    if (!await hasInternetConnection()) {
      if (Get.currentRoute != AppRoutes.splash) return;
      Get.offAllNamed(AppRoutes.connectionCheck);
      return;
    }

    final route = await resolveNextRoute();

    if (Get.currentRoute != AppRoutes.splash) return;
    Get.offAllNamed(route);
  }
}
