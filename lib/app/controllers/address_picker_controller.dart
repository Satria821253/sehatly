import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../routes/app_routes.dart';
import '../services/nominatim_service.dart';

export '../services/nominatim_service.dart' show AddressResult;

class AddressPickerController extends GetxController {
  static const String kSelectedAddress = 'selected_address';

  final _service = NominatimService();

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
    results.assignAll(await _service.search(q));
    isLoading.value = false;
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
