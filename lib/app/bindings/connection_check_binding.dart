import 'package:get/get.dart';

import '../controllers/connection_check_controller.dart';

/// Binding untuk layar "Cek Jaringanmu".
///
/// [ConnectionCheckController] dibuat di sini bila belum terdaftar (tes
/// biasanya sudah `Get.put` lebih dulu). Pemeriksaan jaringannya memakai
/// `hasInternetConnection()`; saat pengujian diganti lewat global
/// `connectivityProbe` di `network_status.dart`.
class ConnectionCheckBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ConnectionCheckController>()) {
      Get.put(ConnectionCheckController());
    }
  }
}
