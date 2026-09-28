import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../routes/app_routes.dart';

class LocationPermissionController extends GetxController
    with WidgetsBindingObserver {
  static const String _kManualAddress = 'manual_address_set';

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
    debugPrint('>>> recheck after settings: $permission');
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      isPermanentlyDenied.value = false;
      _navigateHome();
    } else if (permission == LocationPermission.denied) {
      // Selalu tanya → request langsung
      isPermanentlyDenied.value = false;
      final result = await Geolocator.requestPermission();
      if (result == LocationPermission.whileInUse ||
          result == LocationPermission.always) {
        _navigateHome();
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
      if (prefs.getBool(_kManualAddress) == true) return AppRoutes.home;
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
        debugPrint('>>> requestPermission: $permission');
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        _navigateHome();
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

  Future<void> chooseManualAddress(BuildContext context) async {
    if (isLoading.value) return;
    await Get.toNamed(AppRoutes.addressPicker);
  }

  void _navigateHome() {
    if (Get.currentRoute == AppRoutes.locationPermission) {
      SharedPreferences.getInstance()
          .then((prefs) => prefs.setBool('has_reached_home', true));
      Get.offAllNamed(AppRoutes.home);
    }
  }
}
