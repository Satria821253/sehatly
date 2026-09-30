import 'package:get/get.dart';

import '../controllers/connection_check_controller.dart';

/// Binding untuk layar "Cek Jaringanmu".
///
/// Catatan: [ConnectionCheckController] sebaiknya sudah terdaftar
/// (mis. lewat `Get.put` dengan checker khusus saat pengujian) — bila belum,
/// dibuat di sini dengan pemeriksaan jaringan sungguhan.
class ConnectionCheckBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ConnectionCheckController>()) {
      Get.put(ConnectionCheckController());
    }
  }
}
