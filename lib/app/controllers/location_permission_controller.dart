import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/prefs_keys.dart';
import '../routes/app_routes.dart';
import '../services/reverse_geocoder.dart';

class LocationPermissionController extends GetxController
    with WidgetsBindingObserver {
  final isLoading = false.obs;
  final isPermanentlyDenied = false.obs;
  bool _waitingForSettings = false;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _checkInitialState();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  Future<void> _checkInitialState() async {
    final permission = await Geolocator.checkPermission();
    isPermanentlyDenied.value = permission == LocationPermission.deniedForever;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingForSettings) {
      _waitingForSettings = false;
      _recheckAfterSettings();
    }
  }

  Future<void> _recheckAfterSettings() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      isPermanentlyDenied.value = false;
      await _onLocationGranted();
    } else if (permission == LocationPermission.denied) {
      // Selalu tanya → request langsung
      isPermanentlyDenied.value = false;
      final result = await Geolocator.requestPermission();
      if (result == LocationPermission.whileInUse ||
          result == LocationPermission.always) {
        await _onLocationGranted();
      } else if (result == LocationPermission.deniedForever) {
        isPermanentlyDenied.value = true;
      }
    } else {
      isPermanentlyDenied.value = true;
    }
  }

  /// Dipanggil dari [SplashController] untuk menentukan route berikutnya.
  static Future<String> nextRoute() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        return AppRoutes.home;
      }
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(PrefsKeys.manualAddressSet) == true) {
        return AppRoutes.home;
      }
      return AppRoutes.locationPermission;
    } catch (_) {
      return AppRoutes.locationPermission;
    }
  }

  Future<void> activateLocation() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      // Sudah permanently denied → buka settings
      if (isPermanentlyDenied.value) {
        _waitingForSettings = true;
        isLoading.value = false;
        await Geolocator.openAppSettings();
        return;
      }

      // Cek service lokasi aktif
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _waitingForSettings = true;
        isLoading.value = false;
        await Geolocator.openLocationSettings();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.deniedForever) {
        isPermanentlyDenied.value = true;
        _waitingForSettings = true;
        isLoading.value = false;
        await Geolocator.openAppSettings();
        return;
      }

      // denied atau belum pernah diminta → tampilkan dialog sistem
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        await _onLocationGranted();
      } else if (permission == LocationPermission.deniedForever) {
        isPermanentlyDenied.value = true;
      }
      // denied (selalu tanya) → tombol tetap "AKTIFKAN LOKASI", user bisa klik lagi
    } catch (e) {
      debugPrint('Location error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Izin baru saja diberikan → ambil lokasi GPS + alamatnya dulu, baru
  /// pindah ke home, supaya kartu alamat di halaman home langsung terisi
  /// (bukan kosong seperti sebelumnya).
  Future<void> _onLocationGranted() async {
    await _captureLocation();
    _navigateHome();
  }

  /// Simpan koordinat GPS lalu reverse geocode ke alamat lengkap.
  /// Gagal di tengah jalan tidak membatalkan navigasi — home tetap terbuka
  /// dan HomeController akan mencoba melengkapi alamatnya sendiri.
  Future<void> _captureLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Hormati alamat yang sudah dipilih user lewat pencarian/peta.
      final saved = prefs.getString(PrefsKeys.selectedAddress);
      if (saved != null && saved.isNotEmpty) return;

      final coords = await currentCoordinates();
      if (coords == null) return;

      await prefs.setDouble(PrefsKeys.selectedLat, coords.lat);
      await prefs.setDouble(PrefsKeys.selectedLng, coords.lng);

      final address = await lookupAddress(coords.lat, coords.lng);
      if (address != null && address.isNotEmpty) {
        await prefs.setString(PrefsKeys.selectedAddress, address);
      }
    } catch (e) {
      debugPrint('Gagal menyimpan lokasi GPS: $e');
    }
  }

  void _navigateHome() {
    if (Get.currentRoute == AppRoutes.locationPermission) {
      SharedPreferences.getInstance()
          .then((prefs) => prefs.setBool(PrefsKeys.hasReachedHome, true));
      Get.offAllNamed(AppRoutes.home);
    }
  }
}
