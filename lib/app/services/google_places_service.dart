import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/address_result.dart';
import 'google_quota.dart';

export '../models/address_result.dart';

/// Endpoint Google Places Autocomplete.
///
/// Di Google Cloud Console kadang yang di-enable "Places API" (legacy) dan
/// kadang "Places API (New)", jadi service ini mencoba keduanya dan mengunci
/// mode yang pertama kali berhasil untuk request berikutnya.
/// **Default-nya Places API (New)** karena itu yang di-enable di console —
/// supaya cold start tidak membuang satu request ke endpoint yang ditolak.
enum PlacesApiMode { legacy, v1 }

/// Search alamat memakai **Google Places Autocomplete** (HTTP langsung).
///
/// Berbeda dengan package `geocoding` (geocoder bawaan Android/iOS) yang
/// tidak bisa dikontrol, API ini mengembalikan prediksi tempat/POI persis
/// seperti di Google Maps — nama jalan, gedung, sekolah, rumah sakit, dll.
class GooglePlacesService {
  /// Legacy: `maps.googleapis.com/maps/api/place/autocomplete/json`
  static const _legacyHost = 'maps.googleapis.com';
  static const _legacyPath = '/maps/api/place/autocomplete/json';

  /// Places API (New): `places.googleapis.com/v1/places:autocomplete`
  static const _v1Url = 'https://places.googleapis.com/v1/places:autocomplete';

  static const _timeout = Duration(seconds: 10);

  /// Mode yang terakhir sukses — dipakai langsung oleh request berikutnya.
  static PlacesApiMode? _activeMode;

  String? _sessionToken;

  /// Mulai sesi autocomplete (dipanggil saat user mulai mengetik).
  /// Google menggabungkan autocomplete + place details dalam satu sesi
  /// penagihan selama token-nya sama.
  void startSession() {
    _sessionToken ??= DateTime.now().microsecondsSinceEpoch.toString();
  }

  /// Akhiri sesi (dipanggil saat alamat dipilih / query dibersihkan).
  void endSession() {
    _sessionToken = null;
  }

  /// `null` = Google gagal (API belum aktif / dibatasi / **kuota harian
  /// habis**) → gunakan fallback OpenStreetMap. List kosong = Google sukses
  /// tapi memang tidak ada hasil.
  Future<List<AddressResult>?> search(String input) async {
    final q = input.trim();
    if (q.isEmpty) return [];

    // Batasi pemakaian Google per hari (masih tahap develop).
    if (!await GoogleQuota.isAllowed()) {
      debugPrint(
        'Kuota Google harian habis (${GoogleQuota.maxPerDay}/hari, '
        'terpakai ${GoogleQuota.used}) → fallback OpenStreetMap',
      );
      return null;
    }

    startSession();

    // Mode yang dulu berhasil diprioritaskan, mode lain jadi cadangan.
    // Urutan default: Places API (New) → legacy.
    final order = <PlacesApiMode>[
      ?_activeMode,
      if (_activeMode != PlacesApiMode.v1) PlacesApiMode.v1,
      if (_activeMode != PlacesApiMode.legacy) PlacesApiMode.legacy,
    ];

    for (final mode in order) {
      final result = await _searchWith(mode, q);
      if (result != null) {
        _activeMode = mode;
        await GoogleQuota.recordSuccess();
        return result;
      }
    }
    debugPrint('Places gagal di semua mode → fallback OpenStreetMap');
    return null;
  }

  /// `null` = request gagal / API belum di-enable (coba mode lain),
  /// list = sukses (bisa kosong).
  ///
  /// `await` di dalam `try` itu wajib: timeout dan body bukan JSON
  /// melempar lewat Future (bukan sinkron) — tanpa await, errornya lolos
  /// ke pemanggil dan fallback OpenStreetMap tidak pernah tercapai.
  Future<List<AddressResult>?> _searchWith(PlacesApiMode mode, String q) async {
    try {
      return mode == PlacesApiMode.legacy
          ? await _searchLegacy(q)
          : await _searchV1(q);
    } catch (e) {
      debugPrint('Places ${mode.name} error: $e');
      return null;
    }
  }

  // ─────────────────────────── Legacy ───────────────────────────

  Future<List<AddressResult>?> _searchLegacy(String q) async {
    final uri = Uri.https(_legacyHost, _legacyPath, {
      'input': q,
      'key': GoogleApi.apiKey,
      'language': GoogleApi.language,
      'components': 'country:${GoogleApi.countryCode}',
      'sessiontoken': ?_sessionToken,
    });

    final res = await http.get(uri).timeout(_timeout);
    if (res.statusCode != 200) {
      debugPrint('Places legacy HTTP ${res.statusCode}');
      return null;
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final status = data['status']?.toString() ?? '';
    if (status != 'OK') {
      debugPrint('Places legacy $status: ${data['error_message'] ?? ''}');
      return null;
    }

    final predictions =
        (data['predictions'] as List? ?? []).cast<Map<String, dynamic>>();
    return predictions.map(_fromLegacy).toList();
  }

  AddressResult _fromLegacy(Map<String, dynamic> p) {
    final structured = p['structured_formatting'] as Map<String, dynamic>? ?? {};
    final main = (structured['main_text'] ?? '').toString();
    final secondary = (structured['secondary_text'] ?? '').toString();
    final description = (p['description'] ?? '').toString();

    return AddressResult(
      label: main.isNotEmpty ? main : description,
      main: main.isNotEmpty ? main : description,
      detail: secondary,
      full: description,
      placeId: p['place_id'] as String?,
    );
  }

  // ──────────────────────── Places API (New) ────────────────────────

  Future<List<AddressResult>?> _searchV1(String q) async {
    final res = await http
        .post(
          Uri.parse(_v1Url),
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': GoogleApi.apiKey,
            'X-Goog-FieldMask':
                'suggestions.placePrediction.placeId,'
                'suggestions.placePrediction.text,'
                'suggestions.placePrediction.structuredFormat',
          },
          body: jsonEncode({
            'input': q,
            'languageCode': GoogleApi.language,
            'regionCode': GoogleApi.countryCode.toUpperCase(),
            'sessionToken': ?_sessionToken,
          }),
        )
        .timeout(_timeout);

    if (res.statusCode != 200) {
      debugPrint('Places v1 HTTP ${res.statusCode}: ${res.body}');
      return null;
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final suggestions = (data['suggestions'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    return suggestions
        .map((s) => s['placePrediction'] as Map<String, dynamic>?)
        .whereType<Map<String, dynamic>>()
        .map(_fromV1)
        .toList();
  }

  AddressResult _fromV1(Map<String, dynamic> p) {
    final structured = p['structuredFormat'] as Map<String, dynamic>? ?? {};
    final main =
        ((structured['mainText'] as Map<String, dynamic>?)?['text'] ?? '')
            .toString();
    final secondary =
        ((structured['secondaryText'] as Map<String, dynamic>?)?['text'] ?? '')
            .toString();
    final description =
        ((p['text'] as Map<String, dynamic>?)?['text'] ?? '').toString();

    // placeId kadang berupa resource name "places/ChIJ..." — buang prefixnya.
    final placeId = (p['placeId'] ?? '').toString().replaceFirst('places/', '');

    return AddressResult(
      label: main.isNotEmpty ? main : description,
      main: main.isNotEmpty ? main : description,
      detail: secondary,
      full: description.isNotEmpty ? description : main,
      placeId: placeId.isEmpty ? null : placeId,
    );
  }
}
