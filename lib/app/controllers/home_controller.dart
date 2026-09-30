import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../pages/address_picker_page.dart';
import '../../widgets/error_message.dart';
import '../config/prefs_keys.dart';
import '../services/reverse_geocoder.dart';

class HomeController extends GetxController {
  /// Alamat terpilih — ditulis oleh AddressPickerController /
  /// map picker / alur izin GPS, dibaca di sini untuk halaman home.
  final address = ''.obs;
  final lat = Rxn<double>();
  final lng = Rxn<double>();
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadAddress();
  }

  Future<void> loadAddress() async {
    isLoading.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      address.value = prefs.getString(PrefsKeys.selectedAddress) ?? '';
      lat.value = prefs.getDouble(PrefsKeys.selectedLat);
      lng.value = prefs.getDouble(PrefsKeys.selectedLng);
    } catch (e) {
      debugPrint('Gagal memuat alamat: $e');
      showSnackFromGlobal(showAddressLoadFailedSnack);
    } finally {
      isLoading.value = false;
    }

    // Alamat kosong → coba lengkapi sendiri (mis. tadi gagal saat izin
    // diberikan karena tidak ada jaringan).
    if (address.value.isEmpty) await _recoverAddress();
  }

  Future<void> _recoverAddress() async {
    var la = lat.value;
    var lo = lng.value;

    // Koordinat belum ada → ambil dari GPS (aman: service ini memeriksa
    // izin dulu dan mengembalikan null bila belum diizinkan).
    if (la == null || lo == null) {
      final coords = await currentCoordinates();
      if (coords == null) return;
      la = coords.lat;
      lo = coords.lng;
      lat.value = la;
      lng.value = lo;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble(PrefsKeys.selectedLat, la);
        await prefs.setDouble(PrefsKeys.selectedLng, lo);
      } catch (e) {
        debugPrint('Gagal menyimpan koordinat: $e');
        showSnackFromGlobal(showAddressSaveFailedSnack);
      }
    }

    final found = await lookupAddress(la, lo);
    if (found == null || found.isEmpty || address.value.isNotEmpty) return;

    address.value = found;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(PrefsKeys.selectedAddress, found);
    } catch (e) {
      debugPrint('Gagal menyimpan alamat: $e');
      showSnackFromGlobal(showAddressSaveFailedSnack);
    }
  }

  /// Lokasi ringkas untuk chip di pojok kanan atas (2 segmen pertama),
  /// contoh: "Jl. Affandi CT X No.16, Santren".
  String get shortAddress {
    final a = address.value;
    if (a.isEmpty) return '';
    final parts = a
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.length <= 2) return parts.join(', ');
    return '${parts[0]}, ${parts[1]}';
  }

  /// Label koordinat, kosong bila belum pernah dipilih dari peta.
  String get coordinateLabel {
    final la = lat.value;
    final lo = lng.value;
    if (la == null || lo == null) return '';
    return '${la.toStringAsFixed(5)}, ${lo.toStringAsFixed(5)}';
  }

  /// Buka sheet pilih alamat, lalu muat ulang alamat terbaru.
  ///
  /// Sengaja dibuka sebagai **bottom sheet** (bukan halaman route): panelnya
  /// bisa digeser ke bawah untuk menutup — lewat pegangan garis di atas atau
  /// geser dari mana pun — tanpa harus menekan tombol back.
  Future<void> openAddressPicker(BuildContext context) async {
    await AddressPickerSheet.show(context);
    await loadAddress();
  }
}
