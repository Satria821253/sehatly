import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../routes/app_routes.dart';
import '../services/nominatim_service.dart';

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
    Get.toNamed(AppRoutes.mapPicker);
  }

  Future<AddressResult?> reverseGeocode(double lat, double lon) {
    return _service.reverseGeocode(lat, lon);
  }

  Future<void> confirmMapAddress(String full, double lat, double lon) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kSelectedAddress, full);
    await prefs.setBool('manual_address_set', true);
    Get.offAllNamed(AppRoutes.home);
  }
}
