import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/address_result.dart';
import 'google_quota.dart';

export '../models/address_result.dart';

/// Reverse geocoding & resolve `place_id` lewat Google Web Services (HTTP
/// langsung), bukan geocoder bawaan Android/iOS.
///
///  - `reverseGeocode()` → Geocoding API (untuk geser pin di map picker)
///  - `fromPlaceId()`    → Geocoding API, fallback ke Place Details (New),
///                         untuk ambil alamat lengkap + koordinat presisi
///                         setelah user memilih hasil autocomplete.
class GoogleGeocodingService {
  static const _host = 'maps.googleapis.com';
  static const _timeout = Duration(seconds: 10);

  /// Saat Google Geocoding menolak (mis. billing belum aktif), request
  /// berikutnya tidak usah dicoba lagi — langsung jatuh ke OSM. Tanpa ini
  /// setiap geser pin harus menunggu request Google yang pasti gagal dulu
  /// (±300 ms) sebelum alamat muncul.
  ///
  /// Dicoba ulang tiap 10 menit supaya begitu billing diaktifkan, aplikasi
  /// pulih sendiri tanpa perlu di-restart.
  static DateTime? _geocodeRetryAt;
  static const _geocodeBackoff = Duration(minutes: 10);

  Future<AddressResult?> reverseGeocode(double lat, double lon) {
    return _geocode({'latlng': '$lat,$lon'});
  }

  /// Endpoint yang terakhir berhasil untuk resolve place_id — dipakai dulu
  /// pada request berikutnya supaya tidak mengulang request cadangan yang
  /// pasti gagal (mis. Geocoding API sedang ditolak).
  static bool _detailsNewFirst = false;

  Future<AddressResult?> fromPlaceId(String placeId) async {
    if (_detailsNewFirst) {
      final detail = await _placeDetailsNew(placeId);
      if (detail != null) return detail;
      final legacy = await _geocode({'place_id': placeId});
      if (legacy != null) _detailsNewFirst = false;
      return legacy;
    }

    final legacy = await _geocode({'place_id': placeId});
    if (legacy != null) return legacy;

    final detail = await _placeDetailsNew(placeId);
    if (detail != null) _detailsNewFirst = true;
    return detail;
  }

  // ───────────────────── Geocoding API (legacy) ─────────────────────

  Future<AddressResult?> _geocode(Map<String, String> query) async {
    // Masih dalam masa istirahat karena pernah ditolak → lewati Google.
    final retryAt = _geocodeRetryAt;
    if (retryAt != null) {
      if (DateTime.now().isBefore(retryAt)) return null;
      _geocodeRetryAt = null; // jendela coba ulang terbuka → coba sekali lagi
    }

    // Batasi pemakaian Google per hari (masih tahap develop).
    if (!await _quotaAllows()) return null;

    try {
      final uri = Uri.https(_host, '/maps/api/geocode/json', {
        ...query,
        'key': GoogleApi.apiKey,
        'language': GoogleApi.language,
      });

      final res = await http.get(uri).timeout(_timeout);
      if (res.statusCode != 200) {
        debugPrint('Geocoding HTTP ${res.statusCode}');
        return null;
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final status = data['status']?.toString() ?? '';
      if (status != 'OK') {
        debugPrint('Geocoding $status: ${data['error_message'] ?? ''}');
        // REQUEST_DENIED (billing/key) & OVER_QUERY_LIMIT (kuota) tidak akan
        // berubah dalam hitungan detik → istirahatkan Google sementara waktu.
        if (status == 'REQUEST_DENIED' || status == 'OVER_QUERY_LIMIT') {
          _geocodeRetryAt = DateTime.now().add(_geocodeBackoff);
          debugPrint(
            'Geocoding $status → coba lagi dalam 10 menit, '
            'sementara memakai OSM.',
          );
        }
        return null;
      }

      final results =
          (data['results'] as List? ?? []).cast<Map<String, dynamic>>();
      if (results.isEmpty) return null;

      final r = results.first;
      final parsed = _buildResult(
        formatted: (r['formatted_address'] ?? '').toString(),
        components: (r['address_components'] as List? ?? [])
            .cast<Map<String, dynamic>>(),
        location: (r['geometry'] as Map<String, dynamic>?)
            ?['location'] as Map<String, dynamic>?,
        placeId: r['place_id'] as String?,
        displayName: '',
      );
      await GoogleQuota.recordSuccess();
      return parsed;
    } catch (e) {
      debugPrint('Geocoding error: $e');
      return null;
    }
  }

  /// Cek kuota harian Google. Kalau habis, request dilewati dan pemanggil
  /// akan memakai fallback OpenStreetMap.
  static Future<bool> _quotaAllows() async {
    if (await GoogleQuota.isAllowed()) return true;
    debugPrint(
      'Kuota Google harian habis (${GoogleQuota.maxPerDay}/hari, '
      'terpakai ${GoogleQuota.used}) → lewati Geocoding',
    );
    return false;
  }

  // ───────────────────── Place Details (New) ─────────────────────

  Future<AddressResult?> _placeDetailsNew(String placeId) async {
    if (!await _quotaAllows()) return null;

    try {
      final uri = Uri.parse(
        'https://places.googleapis.com/v1/places/$placeId',
      ).replace(queryParameters: {'languageCode': GoogleApi.language});

      final res = await http.get(
        uri,
        headers: {
          'X-Goog-Api-Key': GoogleApi.apiKey,
          // Field mask Place Details (New) memakai nama field polos.
          // `placeId` tidak ada di response — id diambil dari `name`.
          'X-Goog-FieldMask':
              'name,displayName,formattedAddress,location,addressComponents',
        },
      ).timeout(_timeout);

      if (res.statusCode != 200) {
        debugPrint('Place Details HTTP ${res.statusCode}: ${res.body}');
        return null;
      }

      final r = jsonDecode(res.body) as Map<String, dynamic>;
      final parsed = _buildResult(
        formatted: (r['formattedAddress'] ?? '').toString(),
        components: (r['addressComponents'] as List? ?? [])
            .cast<Map<String, dynamic>>()
            .map((c) => {
                  // Place Details (New) memakai longText (Geocoding API
                  // memakai long_name) — diseragamkan di sini.
                  'long_name': c['longText'] ?? c['longName'],
                  'types': c['types'],
                })
            .toList(),
        location: r['location'] as Map<String, dynamic>?,
        placeId: (r['name'] ?? '').toString().replaceFirst('places/', ''),
        displayName:
            (r['displayName'] as Map<String, dynamic>?)?['text']?.toString() ??
                '',
      );
      await GoogleQuota.recordSuccess();
      return parsed;
    } catch (e) {
      debugPrint('Place Details error: $e');
      return null;
    }
  }

  // ──────────────────────────── Parsing ────────────────────────────

  AddressResult _buildResult({
    required String formatted,
    required List<Map<String, dynamic>> components,
    required Map<String, dynamic>? location,
    required String? placeId,
    required String displayName,
  }) {
    String component(String type) {
      for (final c in components) {
        final types = (c['types'] as List? ?? []).map((e) => e.toString());
        if (types.contains(type)) return (c['long_name'] ?? '').toString();
      }
      return '';
    }

    // Judul: nama gedung/POI kalau ada, kalau tidak pakai bagian pertama
    // dari formatted address (biasanya nama jalan).
    var label = displayName.trim();
    if (label.isEmpty) {
      for (final c in components) {
        final types =
            (c['types'] as List? ?? []).map((e) => e.toString()).toList();
        if (types.contains('point_of_interest') ||
            types.contains('establishment') ||
            types.contains('premise')) {
          label = (c['long_name'] ?? '').toString();
          break;
        }
      }
    }
    if (label.isEmpty) label = formatted.split(',').first.trim();

    // Komponen alamat (jalan, kelurahan, kecamatan, kota, kabupaten,
    // provinsi, kode pos) sebagai cadangan bila formatted address kosong.
    final parts = [
      component('route'),
      component('neighborhood'),
      component('sublocality'),
      component('locality'),
      component('administrative_area_level_5'),
      component('administrative_area_level_4'),
      component('administrative_area_level_3'),
      component('administrative_area_level_2'),
      component('administrative_area_level_1'),
      component('postal_code'),
    ].where((e) => e.isNotEmpty).toSet().toList();

    final lat = (location?['latitude'] ?? location?['lat']) as num?;
    final lng = (location?['longitude'] ?? location?['lng']) as num?;

    return AddressResult(
      label: label,
      main: label,
      detail: formatted.isNotEmpty
          ? _stripLabel(formatted, label)
          : parts.skip(1).join(', '),
      full: formatted.isNotEmpty
          ? formatted
          : (parts.isNotEmpty ? parts.join(', ') : label),
      lat: lat?.toDouble(),
      lng: lng?.toDouble(),
      placeId: (placeId == null || placeId.isEmpty) ? null : placeId,
    );
  }

  /// Bagian alamat setelah label, untuk subtitle daftar hasil.
  String _stripLabel(String formatted, String label) {
    if (label.isEmpty || !formatted.startsWith(label)) return formatted;
    var rest = formatted.substring(label.length).trim();
    if (rest.startsWith(',')) rest = rest.substring(1).trim();
    return rest;
  }
}
