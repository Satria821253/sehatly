import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/address_result.dart';

export '../models/address_result.dart';

class NominatimService {
  static const _baseUrl = 'nominatim.openstreetmap.org';
  static const _headers = {'User-Agent': 'SehatlyApp/1.0'};

  Future<AddressResult?> reverseGeocode(double lat, double lon) async {
    try {
      final uri = Uri.https(_baseUrl, '/reverse', {
        'lat': lat.toString(),
        'lon': lon.toString(),
        'format': 'json',
        'addressdetails': '1',
        'accept-language': 'id',
      });
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data.containsKey('display_name')) {
          return AddressResult.fromNominatim(data);
        }
      }
    } catch (e) {
      debugPrint('Nominatim reverse error: $e');
    }
    return null;
  }

  Future<List<AddressResult>> search(String q) async {
    try {
      final uri = Uri.https(_baseUrl, '/search', {
        'q': q,
        'format': 'json',
        'addressdetails': '1',
        'limit': '10',
        'countrycodes': 'id',
        'accept-language': 'id',
      });
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data
            .map((e) => AddressResult.fromNominatim(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Nominatim error: $e');
    }
    return [];
  }
}
