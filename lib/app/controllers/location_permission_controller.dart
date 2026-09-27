import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../routes/app_routes.dart';

class LocationPermissionController extends GetxController
    with WidgetsBindingObserver {
  static const String _kManualAddress = 'manual_address_set';
  static const String _kDenied = 'permission_denied';

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
    if (permission == LocationPermission.deniedForever) {
      isPermanentlyDenied.value = true;
      return;
    }
    // Cek flag — user pernah tolak dialog sebelumnya
    final prefs = await SharedPreferences.getInstance();
    isPermanentlyDenied.value = prefs.getBool(_kDenied) ?? false;
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
        permission == LocationPermission.always ||
        permission == LocationPermission.denied) {
      // denied = "selalu tanya" → reset flag, masuk home
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kDenied);
      isPermanentlyDenied.value = false;
      _navigateHome();
    } else if (permission == LocationPermission.deniedForever) {
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
      if (isPermanentlyDenied.value) {
        _waitingForSettings = true;
        isLoading.value = false;
        await Geolocator.openAppSettings();
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _waitingForSettings = true;
        isLoading.value = false;
        await Geolocator.openLocationSettings();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('>>> checkPermission: $permission');

      if (permission == LocationPermission.deniedForever) {
        isPermanentlyDenied.value = true;
        _waitingForSettings = true;
        isLoading.value = false;
        await Geolocator.openAppSettings();
        return;
      }

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint('>>> requestPermission: $permission');
      }

      final prefs = await SharedPreferences.getInstance();
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        await prefs.remove(_kDenied);
        _navigateHome();
      } else {
        // denied atau deniedForever → simpan flag, ubah tombol ke "PERGI KE PENGATURAN"
        isPermanentlyDenied.value = true;
        await prefs.setBool(_kDenied, true);
      }
    } catch (e) {
      debugPrint('Location error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> chooseManualAddress(BuildContext context) async {
    if (isLoading.value) return;
    // Lazy import untuk hindari circular dependency
    await Get.toNamed(AppRoutes.addressPicker);
  }

  void _navigateHome() {
    if (Get.currentRoute == AppRoutes.locationPermission) {
      Get.offAllNamed(AppRoutes.home);
    }
  }
}
