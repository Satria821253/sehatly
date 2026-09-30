import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/prefs_keys.dart';
import '../routes/app_routes.dart';
import '../services/google_geocoding_service.dart';
import '../services/google_places_service.dart';
import '../services/network_status.dart';
import '../services/nominatim_service.dart';
import '../../widgets/error_message.dart';

class AddressPickerController extends GetxController {
  final _places = GooglePlacesService();
  final _geocoding = GoogleGeocodingService();

  /// Fallback OpenStreetMap — dipakai hanya bila Google gagal
  /// (mis. billing belum aktif / API belum di-enable).
  final _osm = NominatimService();

  final TextEditingController searchController = TextEditingController();
  final query = ''.obs;
  final results = <AddressResult>[].obs;
  final isLoading = false.obs;
  final isSelecting = false.obs;

  Timer? _debounce;

  /// Nomor urut request — response yang datang terlambat (stale) dibuang,
  /// supaya hasil pencarian lama tidak menimpa yang baru.
  int _requestSeq = 0;

  /// true → internet mati saat dicari; area hasil menampilkan panel
  /// "Cek Jaringanmu" + tombol coba lagi (bukan toast, bukan shimmer
  /// tanpa ujung).
  final offline = false.obs;

  @override
  void onClose() {
    _debounce?.cancel();
    searchController.dispose();
    super.onClose();
  }

  void onQueryChanged(String value) {
    query.value = value;
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      _requestSeq++;
      isLoading.value = false;
      results.clear();
      _places.endSession();
      offline.value = false;
      return;
    }
    _places.startSession();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(value));
  }

  void clearQuery() {
    searchController.clear();
    onQueryChanged('');
  }

  Future<void> _search(String q) async {
    final seq = ++_requestSeq;
    isLoading.value = true;
    try {
      // Cek koneksi dulu: saat internet mati jangan menunggu timeout tiap
      // layanan (bisa lebih dari 20 detik) — shimmer cukup sebentar, lalu
      // panel "Cek Jaringanmu" tampil di area hasil.
      if (!await hasInternetConnection()) {
        if (seq != _requestSeq) return; // sudah ada pencarian baru — buang
        offline.value = true;
        results.clear();
        return;
      }
      if (seq != _requestSeq) return; // sudah ada pencarian baru — buang
      offline.value = false;

      // Utama: Google Places Autocomplete. Kalau gagal → OpenStreetMap.
      var found = await _places.search(q);
      if (seq != _requestSeq) return; // sudah ada pencarian baru — buang

      if (found == null) {
        found = await _osm.search(q);
        if (seq != _requestSeq) return;
      }

      results.assignAll(found);
      isLoading.value = false;

      // Lengkapi 3 item pertama dengan alamat detail (nomor, kecamatan,
      // kode pos) supaya langsung kelihatan sebelum dipilih.
      await _enrichTopResults(seq);
    } catch (e) {
      // Gagal di tengah jalan (timeout, body bukan JSON, prefs bermasalah)
      // — jangan biarkan shimmer berputar tanpa ujung.
      debugPrint('Gagal mencari alamat: $e');
      if (seq != _requestSeq) return;
      results.clear();
      offline.value = !await hasInternetConnection();
    } finally {
      // Hanya pencarian terbaru yang berhak mengubah state; yang sudah
      // basi tidak boleh mematikan loading milik pencarian baru.
      if (seq == _requestSeq) isLoading.value = false;
    }
  }

  /// Cek koneksi ulang lalu cari lagi dengan query yang sama — dipanggil
  /// tombol "Coba Lagi" pada panel "Cek Jaringanmu".
  Future<void> retrySearch() async {
    final q = query.value.trim();
    if (q.isEmpty) return;
    await _search(q);
  }

  /// Perkaya hasil pencarian dengan Place Details untuk [limit] item pertama.
  /// Kalau kuota Google habis, method di dalam service akan mengembalikan
  /// null dan daftar tetap tampil dengan data autocomplete-nya.
  Future<void> _enrichTopResults(int seq, {int limit = 3}) async {
    final targets = results
        .take(limit)
        .where((r) => r.placeId != null && !r.placeId!.startsWith('osm:'))
        .toList();
    if (targets.isEmpty) return;

    final details = await Future.wait(
      targets.map((r) => _geocoding.fromPlaceId(r.placeId!)),
    );
    if (seq != _requestSeq) return; // sudah ada pencarian baru — buang

    for (var i = 0; i < targets.length; i++) {
      final detail = details[i];
      if (detail == null) continue;
      final source = targets[i];
      final idx = results.indexWhere((r) => r.placeId == source.placeId);
      if (idx == -1) continue;

      results[idx] = source.copyWith(
        detail: detail.detail,
        full: detail.full,
        lat: detail.lat,
        lng: detail.lng,
      );
    }
  }

  Future<void> selectAddress(AddressResult address) async {
    if (isSelecting.value) return;
    isSelecting.value = true;
    isLoading.value = true;

    // Hasil Google: ambil alamat lengkap + koordinat presisi via place_id.
    // Hasil OpenStreetMap (prefix "osm:") sudah lengkap dari daftar,
    // jadi tidak perlu request tambahan.
    //
    // Gagal mengambil detail tidak membatalkan pemilihan — pakai hasil
    // autocomplete apa adanya, supaya state tidak tersangkut hanya karena
    // satu request tambahan gagal.
    var resolved = address;
    if (address.placeId != null && !address.placeId!.startsWith('osm:')) {
      try {
        final detail = await _geocoding.fromPlaceId(address.placeId!);
        if (detail != null) resolved = detail;
      } catch (e) {
        debugPrint('Gagal mengambil detail alamat: $e');
      }
    }

    try {
      await _persistSelected(
        resolved.full,
        lat: resolved.lat,
        lng: resolved.lng,
      );
    } catch (e) {
      // Penyimpanan penuh/bermasalah → jangan pindah halaman, user tetap
      // di sheet dan bisa menekan item yang sama sekali lagi.
      debugPrint('Gagal menyimpan alamat: $e');
      _places.endSession();
      isLoading.value = false;
      isSelecting.value = false;
      showSnackFromGlobal(showAddressSaveFailedSnack);
      return;
    }

    _places.endSession();
    isLoading.value = false;
    isSelecting.value = false;

    Get.back();
    Get.offAllNamed(AppRoutes.home);
  }

  void pickOnMap() {
    Get.toNamed(AppRoutes.mapPicker);
  }

  /// Reverse geocode: Google lebih dulu, kalau gagal fallback ke OSM.
  Future<AddressResult?> reverseGeocode(double lat, double lon) async {
    return await _geocoding.reverseGeocode(lat, lon) ??
        await _osm.reverseGeocode(lat, lon);
  }

  Future<void> confirmMapAddress(String full, double lat, double lon) async {
    try {
      await _persistSelected(full, lat: lat, lng: lon);
    } catch (e) {
      // Gagal menyimpan → tetap di peta supaya tombol bisa ditekan lagi.
      debugPrint('Gagal menyimpan alamat (peta): $e');
      showSnackFromGlobal(showAddressSaveFailedSnack);
      return;
    }
    Get.offAllNamed(AppRoutes.home);
  }

  /// Simpan hasil pemilihan ke SharedPreferences — dipakai pemilih alamat
  /// maupun peta, supaya kunci yang ditulis selalu sama dan tidak gampang
  /// berbeda saat salah satunya diubah.
  ///
  /// `hasReachedHome` ikut diset di sini: kunjungan berikutnya menampilkan
  /// intro "Penggunaan Data & Izin" bila `hasSeenIntro` masih false —
  /// berlaku untuk semua jalur masuk home (izin GPS, pencarian, peta).
  Future<void> _persistSelected(
    String full, {
    double? lat,
    double? lng,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefsKeys.selectedAddress, full);
    if (lat != null && lng != null) {
      await prefs.setDouble(PrefsKeys.selectedLat, lat);
      await prefs.setDouble(PrefsKeys.selectedLng, lng);
    }
    await prefs.setBool(PrefsKeys.manualAddressSet, true);
    await prefs.setBool(PrefsKeys.hasReachedHome, true);
  }
}
