import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../pages/address_picker_page.dart';
import '../../widgets/error_message.dart';
import '../config/prefs_keys.dart';
import '../services/network_status.dart';
import '../services/reverse_geocoder.dart';

class HomeController extends GetxController with WidgetsBindingObserver {
  /// Alamat terpilih — ditulis oleh AddressPickerController /
  /// map picker / alur izin GPS, dibaca di sini untuk halaman home.
  final address = ''.obs;
  final lat = Rxn<double>();
  final lng = Rxn<double>();
  final isLoading = true.obs;

  /// true → tidak ada internet. Isi halaman disembunyikan dan hanya
  /// Lottie loading yang tampil, lalu panel "Cek Jaringanmu".
  final offline = false.obs;

  /// true → masa tenggang Lottie lewat tapi koneksi belum juga pulih →
  /// tampilkan panel "Cek Jaringanmu" + tombol Coba Lagi.
  final offlinePanelVisible = false.obs;

  /// true → lookup alamat sudah dicoba tapi gagal (koordinat ada, alamat
  /// tidak) — kartu alamat menampilkan ajakan memilih manual, bukan teks
  /// "Menentukan alamat…" yang seolah terus diproses tanpa pernah selesai.
  final addressLookupFailed = false.obs;

  /// true → sedang memeriksa koneksi (ditekan dari tombol Coba Lagi).
  final checkingConnection = false.obs;

  Timer? _pollTimer;
  Timer? _graceTimer;

  /// Interval polling yang sedang berjalan — dicek supaya timer tidak
  /// dibuat ulang tiap cek koneksi yang hasilnya sama.
  Duration? _pollInterval;

  /// Lottie tampil dulu sekian detik sebelum panel error muncul — kalau
  /// internet hanya lemot, user sudah masuk isi halaman tanpa sempat
  /// melihat pesan error.
  static const _gracePeriod = Duration(seconds: 3);

  /// Cek ulang tiap 5 detik **saat offline** → internet pulih, isi tampil
  /// sendiri tanpa perlu diapa-apakan user.
  static const _pollOffline = Duration(seconds: 5);

  /// Cek ulang tiap 30 detik **saat online** → putusnya koneksi (kuota
  /// habis, pindah jaringan) tetap terdeteksi walau user diam di halaman
  /// ini. Tanpa ini, polling berhenti begitu koneksi pulih untuk pertama
  /// kali dan putus berikutnya tidak pernah diketahui.
  static const _pollOnline = Duration(seconds: 30);

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    loadAddress();
    checkConnection();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPolling();
    _graceTimer?.cancel();
    super.onClose();
  }

  /// Aplikasi ke latar belakang → polling dihentikan (hemat baterai).
  /// Kembali ke depan → cek sekali langsung, polling tersambung lagi.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkConnection();
    } else if (state == AppLifecycleState.paused) {
      _stopPolling();
    }
  }

  /// Cek koneksi sekali lalu atur polling sesuai hasilnya: offline →
  /// polling rapat (5 dtk) + masa tenggang Lottie; online → polling
  /// longgar (30 dtk) + panel dibersihkan.
  Future<void> checkConnection() async {
    final online = await hasInternetConnection();
    offline.value = !online;

    if (offline.value) {
      _schedulePoll(_pollOffline);

      // Baru beberapa detik → tampilkan Lottie dulu, panel belakangan.
      _graceTimer ??= Timer(_gracePeriod, () {
        if (offline.value) offlinePanelVisible.value = true;
      });
      return;
    }

    _schedulePoll(_pollOnline);
    _graceTimer?.cancel();
    _graceTimer = null;
    offlinePanelVisible.value = false;

    // Baru pulih → lengkapi alamat yang masih kosong / masih koordinat.
    if (address.value.isEmpty || _isRawCoordinates(address.value)) {
      loadAddress();
    }
  }

  /// Jadwalkan polling dengan [interval]; kalau timer sudah berjalan
  /// dengan interval sama, dibiarkan (tidak di-reset tiap cek).
  void _schedulePoll(Duration interval) {
    if (_pollTimer != null && _pollInterval == interval) return;
    _pollTimer?.cancel();
    _pollInterval = interval;
    _pollTimer = Timer.periodic(interval, (_) => checkConnection());
  }

  /// Hentikan polling — dipanggil saat aplikasi ke latar belakang dan
  /// saat controller ditutup.
  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _pollInterval = null;
  }

  /// Tombol "Coba Lagi" pada panel offline — cek koneksi sekarang juga.
  Future<void> retryConnection() async {
    if (checkingConnection.value) return;
    checkingConnection.value = true;
    try {
      await checkConnection();
    } finally {
      checkingConnection.value = false;
    }
  }

  Future<void> loadAddress() async {
    isLoading.value = true;
    addressLookupFailed.value = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      address.value = prefs.getString(PrefsKeys.selectedAddress) ?? '';
      lat.value = prefs.getDouble(PrefsKeys.selectedLat);
      lng.value = prefs.getDouble(PrefsKeys.selectedLng);
    } catch (e) {
      debugPrint('Gagal memuat alamat: $e');
      showSnackFromGlobal(showAddressLoadFailedSnack);
    } finally {
      isLoading.value = false;
    }

    // Alamat masih kosong (tadi gagal saat izin diberikan tanpa jaringan)
    // atau masih berupa koordinat mentah (dipilih dari peta saat offline)
    // → lengkapi sendiri.
    if (address.value.isEmpty || _isRawCoordinates(address.value)) {
      await _recoverAddress();
    }
  }

  Future<void> _recoverAddress() async {
    var la = lat.value;
    var lo = lng.value;

    // Koordinat belum ada → ambil dari GPS (aman: service ini memeriksa
    // izin dulu dan mengembalikan null bila belum diizinkan).
    if (la == null || lo == null) {
      final coords = await currentCoordinates();
      if (coords == null) return;
      la = coords.lat;
      lo = coords.lng;
      lat.value = la;
      lng.value = lo;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble(PrefsKeys.selectedLat, la);
        await prefs.setDouble(PrefsKeys.selectedLng, lo);
      } catch (e) {
        debugPrint('Gagal menyimpan koordinat: $e');
        showSnackFromGlobal(showAddressSaveFailedSnack);
      }
    }

    final current = address.value;
    // Sudah alamat lengkap → tidak ada yang perlu diperbaiki.
    if (current.isNotEmpty && !_isRawCoordinates(current)) return;

    final found = await lookupAddress(la, lo);
    if (found == null || found.isEmpty) {
      // Gagal (biasanya karena jaringan) → tandai, supaya kartu alamat
      // berhenti menampilkan "Menentukan alamat…" seolah prosesnya masih
      // berjalan padahal sudah tidak ada request lagi.
      if (current.isEmpty) addressLookupFailed.value = true;
      return;
    }

    address.value = found;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(PrefsKeys.selectedAddress, found);
    } catch (e) {
      debugPrint('Gagal menyimpan alamat: $e');
      showSnackFromGlobal(showAddressSaveFailedSnack);
    }
  }

  /// true bila [text] masih berupa koordinat mentah ("−7.79560,
  /// 110.36950") — hasil konfirmasi peta saat sedang offline, perlu
  /// diganti alamat lengkap begitu internet tersedia.
  static bool _isRawCoordinates(String text) {
    final parts = text.split(',');
    if (parts.length != 2) return false;
    return double.tryParse(parts[0].trim()) != null &&
        double.tryParse(parts[1].trim()) != null;
  }

  /// Lokasi ringkas untuk chip di pojok kanan atas (2 segmen pertama),
  /// contoh: "Jl. Affandi CT X No.16, Santren".
  String get shortAddress {
    final a = address.value;
    if (a.isEmpty) return '';
    final parts = a
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.length <= 2) return parts.join(', ');
    return '${parts[0]}, ${parts[1]}';
  }

  /// Label koordinat, kosong bila belum pernah dipilih dari peta.
  String get coordinateLabel {
    final la = lat.value;
    final lo = lng.value;
    if (la == null || lo == null) return '';
    return '${la.toStringAsFixed(5)}, ${lo.toStringAsFixed(5)}';
  }

  /// Buka sheet pilih alamat, lalu muat ulang alamat terbaru.
  ///
  /// Sengaja dibuka sebagai **bottom sheet** (bukan halaman route): panelnya
  /// bisa digeser ke bawah untuk menutup — lewat pegangan garis di atas atau
  /// geser dari mana pun — tanpa harus menekan tombol back.
  Future<void> openAddressPicker(BuildContext context) async {
    await AddressPickerSheet.show(context);
    await loadAddress();
  }
}
