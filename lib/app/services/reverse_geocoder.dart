import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'google_geocoding_service.dart';
import 'nominatim_service.dart';

/// Reverse geocode koordinat → alamat lengkap.
///
/// Urutan: Google Geocoding dulu, lalu fallback OpenStreetMap (kedua service
/// sudah menangkap error-nya masing-masing; timeout di sini jadi pengaman
/// ekstra supaya tidak menggantung — dipakai di alur izin lokasi yang
/// menampilkan tombol loading).
///
/// Mengembalikan null bila keduanya gagal.
Future<String?> lookupAddress(double lat, double lng) async {
  try {
    final google = await GoogleGeocodingService()
        .reverseGeocode(lat, lng)
        .timeout(const Duration(seconds: 8));
    if (google != null && google.full.isNotEmpty) return google.full;
  } catch (e) {
    debugPrint('>>> lookup alamat (Google): $e');
  }

  try {
    final osm = await NominatimService()
        .reverseGeocode(lat, lng)
        .timeout(const Duration(seconds: 12));
    if (osm != null && osm.full.isNotEmpty) return osm.full;
  } catch (e) {
    debugPrint('>>> lookup alamat (OSM): $e');
  }
  return null;
}

/// Koordinat GPS saat ini — null bila izin belum diberikan, service lokasi
/// mati, atau platform tidak mendukung (mis. saat widget test).
Future<({double lat, double lng})?> currentCoordinates() async {
  try {
    final permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      return null;
    }
    final pos = await Geolocator.getCurrentPosition()
        .timeout(const Duration(seconds: 15));
    return (lat: pos.latitude, lng: pos.longitude);
  } catch (e) {
    debugPrint('>>> ambil koordinat GPS: $e');
    return null;
  }
}
