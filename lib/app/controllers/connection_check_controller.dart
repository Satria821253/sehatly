import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../routes/app_routes.dart';
import '../services/network_status.dart';
import 'splash_controller.dart';

/// Layar "Cek Jaringanmu" (setelah splash, saat internet jelek/mati).
///
/// Alurnya:
/// 1. Masuk → langsung memeriksa koneksi (Lottie berputar, teks
///    "Memeriksa koneksi…", tombol disembunyikan).
/// 2. Koneksi OK → lanjut ke halaman tujuan (intro/izin/home).
/// 3. Cek otomatis gagal → tombol **Coba Lagi** muncul.
/// 4. Coba Lagi ditekan tapi masih mati → user **tidak ditahan terus** di
///    sini: lanjut ke halaman tujuan seperti biasa (user lama → home mode
///    offline, pengguna baru → halaman izin lokasi/intro), jadi logika
///    onboarding tidak pernah terlewat.
///
/// Pemeriksaan jaringan memakai [hasInternetConnection]. Saat pengujian,
/// ganti global `connectivityProbe` (lihat `network_status.dart`) —
/// dipakai oleh `test/offline_flow_test.dart` lewat setUp/tearDown.
class ConnectionCheckController extends GetxController {
  /// true → sedang memeriksa koneksi (Lottie + "Memeriksa koneksi…").
  final checking = false.obs;

  /// true → cek otomatis pertama sudah gagal, jadi kegagalan berikutnya
  /// berarti user sudah menekan "Coba Lagi" → lanjut ke halaman tujuan.
  bool _autoCheckFailed = false;

  @override
  void onInit() {
    super.onInit();
    check();
  }

  Future<void> check() async {
    if (checking.value) return; // jangan dobel saat tombol disentuh cepat
    checking.value = true;
    try {
      if (await hasInternetConnection() || _autoCheckFailed) {
        await _leave();
        return; // halaman sudah berganti
      }

      // Cek otomatis pertama (langsung setelah splash) gagal → cukup
      // tampilkan tombol. Percobaan user ternyata masih gagal → jangan
      // menahan dia terus di sini: lanjut ke halaman tujuan seperti biasa
      // — user lama langsung home mode offline, pengguna baru tetap
      // melewati halaman izin lokasi / intro dulu.
      _autoCheckFailed = true;
    } finally {
      // Selalu reset supaya layar tidak pernah terkunci di "Memeriksa
      // koneksi…" tanpa tombol — termasuk bila penentuan route melempar.
      checking.value = false;
    }
  }

  /// Menuju halaman tujuan sesuai status onboarding. Bila penentuan route
  /// gagal, jatuh ke home supaya user tidak terkunci di layar cek.
  Future<void> _leave() async {
    String route;
    try {
      route = await SplashController.resolveNextRoute();
    } catch (e) {
      debugPrint('Gagal menentukan halaman tujuan: $e');
      route = AppRoutes.home;
    }
    Get.offAllNamed(route);
  }
}
