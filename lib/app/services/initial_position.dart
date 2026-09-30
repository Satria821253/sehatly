import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/prefs_keys.dart';
import 'reverse_geocoder.dart';

/// Posisi cadangan: lokasi saat ini → alamat terakhir dipilih → pusat kota.
const LatLng kFallbackCenter = LatLng(-7.7956, 110.3695);

/// Titik awal peta saat halaman dibuka.
///
/// Urutan resolusi:
///   1) GPS saat ini (maks [timeout]) — inilah yang membuat peta langsung
///      terbuka di lokasi user;
///   2) lokasi terakhir yang pernah dipilih user (tersimpan di prefs);
///   3) pusat kota sebagai jaring pengaman.
///
/// Hasilnya selalu pasti, jadi peta tidak pernah dirender di titik acak
/// lalu melompat ("angawur").
Future<LatLng> resolveInitialPosition({
  Duration timeout = const Duration(seconds: 6),
}) async {
  // 1) Lokasi saat ini.
  try {
    final coords = await currentCoordinates().timeout(
      timeout,
      onTimeout: () => null,
    );
    if (coords != null) return LatLng(coords.lat, coords.lng);
  } catch (e) {
    debugPrint('Gagal mengambil lokasi awal: $e');
  }

  // 2) Lokasi terakhir yang pernah dipilih user.
  try {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(PrefsKeys.selectedLat);
    final lng = prefs.getDouble(PrefsKeys.selectedLng);
    if (lat != null && lng != null) return LatLng(lat, lng);
  } catch (e) {
    debugPrint('Gagal membaca lokasi tersimpan: $e');
  }

  // 3) Terakhir: pusat default.
  return kFallbackCenter;
}
