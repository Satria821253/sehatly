import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/address_result.dart';

export '../models/address_result.dart';

/// Fallback pencarian alamat memakai **OpenStreetMap Nominatim** — gratis,
/// tanpa API key, tanpa billing.
///
/// Dipakai sebagai cadangan di tiga tempat: pencarian alamat (bila Google
/// Places gagal), reverse geocode alur izin lokasi/home, dan map picker
/// (bila Google Geocoding gagal). Begitu Google jalan, cadangan ini otomatis
/// tidak terpakai.
///
/// Kebijakan Nominatim: maksimal 1 request/detik + User-Agent wajib.
class NominatimService {
  static const _host = 'nominatim.openstreetmap.org';
  static const _headers = {'User-Agent': 'SehatlyApp/1.0 (address lookup)'};
  static const _timeout = Duration(seconds: 10);

  /// Jeda minimum antar request agar tidak melanggar aturan Nominatim.
  static const _minInterval = Duration(milliseconds: 1100);
  static DateTime? _lastCall;

  static Future<void> _throttle() async {
    final last = _lastCall;
    if (last != null) {
      final wait = _minInterval - DateTime.now().difference(last);
      if (wait > Duration.zero) {
        // Klaim slot berikutnya sebelum menunggu: pemanggil kedua yang
        // masuk selama jeda ini menghitung dari slot yang sudah diklaim,
        // jadi dua request tidak pernah meluncur berdekatan.
        _lastCall = DateTime.now().add(wait);
        await Future.delayed(wait);
        return;
      }
    }
    _lastCall = DateTime.now();
  }

  Future<AddressResult?> reverseGeocode(double lat, double lon) async {
    try {
      await _throttle();
      final uri = Uri.https(_host, '/reverse', {
        'lat': lat.toString(),
        'lon': lon.toString(),
        'format': 'jsonv2',
        'addressdetails': '1',
        'accept-language': 'id',
      });

      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode != 200) {
        debugPrint('Nominatim reverse HTTP ${res.statusCode}');
        return null;
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['display_name'] == null) return null;
      return AddressResult.fromNominatim(data);
    } catch (e) {
      debugPrint('Nominatim reverse error: $e');
      return null;
    }
  }

  Future<List<AddressResult>> search(String q) async {
    try {
      await _throttle();
      final uri = Uri.https(_host, '/search', {
        'q': q.trim(),
        'format': 'jsonv2',
        'addressdetails': '1',
        'limit': '5',
        'countrycodes': 'id',
        'accept-language': 'id',
      });

      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode != 200) {
        debugPrint('Nominatim search HTTP ${res.statusCode}');
        return [];
      }

      final data = jsonDecode(res.body) as List;
      return data
          .map((e) => AddressResult.fromNominatim(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Nominatim search error: $e');
      return [];
    }
  }
}
