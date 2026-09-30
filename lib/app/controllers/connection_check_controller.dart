import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

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
///    sini: langsung masuk home mode offline (isi = Lottie beberapa detik,
///    lalu panel "Cek Jaringanmu" dengan cek ulang otomatis tiap 5 detik).
///
/// [checker] bisa disuntikkan saat pengujian supaya tes tidak bergantung
/// pada koneksi jaringan sungguhan.
class ConnectionCheckController extends GetxController {
  ConnectionCheckController({this.checker});

  /// Opsional: sumber pemeriksaan koneksi. Saat pengujian disuntikkan
  /// fungsi palsu supaya tes tidak bergantung pada jaringan sungguhan;
  /// saat aplikasi berjalan dibiarkan null (memakai [hasInternetConnection]).
  final Future<bool> Function()? checker;

  /// true → sedang memeriksa koneksi (Lottie + "Memeriksa koneksi…").
  final checking = false.obs;

  /// true → pengecekan terakhir gagal (judul kembali ke "Cek Jaringanmu").
  final failed = false.obs;

  /// true → cek otomatis pertama sudah gagal, jadi kegagalan berikutnya
  /// berarti user sudah menekan "Coba Lagi" → lanjut ke home mode offline.
  bool _autoCheckFailed = false;

  @override
  void onInit() {
    super.onInit();
    check();
  }

  Future<bool> _probe() async {
    final probe = checker;
    return probe != null ? await probe() : await hasInternetConnection();
  }

  Future<void> check() async {
    if (checking.value) return; // jangan dobel saat tombol disentuh cepat
    checking.value = true;
    failed.value = false;

    final online = await _probe();
    if (online) {
      final route = await SplashController.resolveNextRoute();
      debugPrint('>>> connection-check: koneksi OK → $route');
      Get.offAllNamed(route);
      return; // halaman sudah berganti
    }

    checking.value = false;
    failed.value = true;

    // Cek otomatis pertama (langsung setelah splash) → cukup tampilkan
    // tombol. Percobaan user ternyata masih gagal → jangan menahan dia
    // terus di sini: lanjut ke halaman tujuan seperti biasa — user lama
    // langsung home mode offline, pengguna baru tetap melewati halaman
    // izin lokasi / intro dulu (logika onboarding tidak boleh terlewat).
    if (_autoCheckFailed) {
      final route = await SplashController.resolveNextRoute();
      debugPrint('>>> connection-check: masih mati → $route (offline)');
      Get.offAllNamed(route);
      return;
    }
    _autoCheckFailed = true;
  }
}
