import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AddressResult {
  final String main;
  final String detail;
  final String full;

  AddressResult({required this.main, required this.detail, required this.full});

  factory AddressResult.fromNominatim(Map<String, dynamic> json) {
    final addr = json['address'] as Map<String, dynamic>? ?? {};
    final main = addr['road'] ??
        addr['neighbourhood'] ??
        addr['suburb'] ??
        addr['village'] ??
        json['display_name'].toString().split(',').first;
    final parts = <String>[];
    if (addr['suburb'] != null) parts.add(addr['suburb']);
    if (addr['city'] != null) parts.add(addr['city']);
    else if (addr['town'] != null) parts.add(addr['town']);
    else if (addr['regency'] != null) parts.add(addr['regency']);
    if (addr['state'] != null) parts.add(addr['state']);
    return AddressResult(
      main: main.toString(),
      detail: parts.join(', '),
      full: json['display_name'].toString(),
    );
  }
}

class NominatimService {
  static const _baseUrl = 'nominatim.openstreetmap.org';
  static const _headers = {'User-Agent': 'SehatlyApp/1.0'};

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
