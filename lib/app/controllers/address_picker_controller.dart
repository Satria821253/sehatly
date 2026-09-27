import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../routes/app_routes.dart';

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
    if (addr['suburb'] != null) {
      parts.add(addr['suburb']);
    }
    if (addr['city'] != null) {
      parts.add(addr['city']);
    } else if (addr['town'] != null) {
      parts.add(addr['town']);
    } else if (addr['regency'] != null) {
      parts.add(addr['regency']);
    }
    if (addr['state'] != null) {
      parts.add(addr['state']);
    }
    return AddressResult(
      main: main.toString(),
      detail: parts.join(', '),
      full: json['display_name'].toString(),
    );
  }
}

class AddressPickerController extends GetxController {
  static const String kSelectedAddress = 'selected_address';

  final TextEditingController searchController = TextEditingController();
  final query = ''.obs;
  final results = <AddressResult>[].obs;
  final isLoading = false.obs;

  Timer? _debounce;

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
      results.clear();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 600), () => _search(value));
  }

  void clearQuery() {
    searchController.clear();
    onQueryChanged('');
  }

  Future<void> _search(String q) async {
    isLoading.value = true;
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': q,
        'format': 'json',
        'addressdetails': '1',
        'limit': '10',
        'countrycodes': 'id',
        'accept-language': 'id',
      });

      final response = await http.get(uri, headers: {
        'User-Agent': 'SehatlyApp/1.0',
      });

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        results.assignAll(
          data.map((e) => AddressResult.fromNominatim(e as Map<String, dynamic>)).toList(),
        );
      }
    } catch (e) {
      debugPrint('Nominatim error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> selectAddress(AddressResult address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kSelectedAddress, address.full);
    await prefs.setBool('manual_address_set', true);
    Get.back();
    Get.offAllNamed(AppRoutes.home);
  }

  void pickOnMap() {
    Get.snackbar(
      'Pilih lewat peta',
      'Fitur peta segera hadir.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF0C1E52),
      colorText: const Color(0xFFFFFFFF),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    );
  }
}
