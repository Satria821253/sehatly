import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app/controllers/address_picker_controller.dart';
import '../app/config/prefs_keys.dart';
import '../app/services/reverse_geocoder.dart';
import '../app/theme/app_colors.dart';

class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  GoogleMapController? _map;

  /// Posisi cadangan: alamat terakhir dipilih → GPS → pusat kota
  /// (baru dipakai kalau memang belum ada data lokasi sama sekali).
  static const _fallbackCenter = LatLng(-7.7956, 110.3695);

  LatLng _center = _fallbackCenter;
  LatLng? _pendingCamera;
  String _title = 'Memuat lokasi...';
  String _address = '';

  /// true = alamat berasal dari reverse geocode (bukan koordinat mentah).
  bool _hasAddress = false;
  bool _loading = true;
  bool _moving = false;

  /// Sedang mengambil lokasi GPS (tombol "lokasi saya" menampilkan spinner).
  bool _locating = false;
  Timer? _debounce;

  final _controller = Get.find<AddressPickerController>();

  @override
  void initState() {
    super.initState();
    _initPosition();
  }

  /// Buka peta di lokasi yang benar — bukan di koordinat hardcode.
  Future<void> _initPosition() async {
    final target = await _resolveInitialPosition();
    if (!mounted) return;
    setState(() => _center = target);
    _moveCamera(target);
    await _fetchAddress(target);
  }

  Future<LatLng> _resolveInitialPosition() async {
    // 1) Lokasi terakhir yang pernah dipilih user.
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble(PrefsKeys.selectedLat);
      final lng = prefs.getDouble(PrefsKeys.selectedLng);
      if (lat != null && lng != null) return LatLng(lat, lng);
    } catch (e) {
      debugPrint('>>> baca lokasi tersimpan gagal: $e');
    }

    // 2) GPS saat ini (sudah mengecek izin + punya timeout sendiri).
    final coords = await currentCoordinates();
    if (coords != null) return LatLng(coords.lat, coords.lng);

    // 3) Terakhir: pusat default — peta tetap harus buka di suatu tempat.
    return _fallbackCenter;
  }

  void _moveCamera(LatLng target) {
    final map = _map;
    if (map != null) {
      map.animateCamera(CameraUpdate.newLatLngZoom(target, 17));
    } else {
      _pendingCamera = target; // dijalankan begitu peta selesai dibuat
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _map?.dispose();
    super.dispose();
  }

  Future<void> _goToMyLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final coords = await currentCoordinates();
      if (!mounted) return;
      if (coords == null) {
        // Jangan diam saja — jelaskan kenapa tombolnya tidak bergerak.
        await _explainGpsUnavailable();
        return;
      }
      final latlng = LatLng(coords.lat, coords.lng);
      _map?.animateCamera(CameraUpdate.newLatLngZoom(latlng, 17));
      await _fetchAddress(latlng);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  /// GPS tidak bisa diambil → beri tahu penyebabnya + jalan pintas ke
  /// pengaturan yang tepat (izin lokasi / sakelar layanan lokasi).
  Future<void> _explainGpsUnavailable() async {
    String message = 'Lokasi perangkat belum tersedia, coba lagi sebentar.';
    String? actionLabel;
    Future<void> Function()? openSettings;

    try {
      final serviceOn = await Geolocator.isLocationServiceEnabled();
      final permission = await Geolocator.checkPermission();
      final hasPermission =
          permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;

      if (!hasPermission) {
        message =
            'Izin lokasi belum diberikan — beri izin dulu supaya tombol '
            'ini bisa membawa peta ke lokasi Anda.';
        actionLabel = 'BUKA PENGATURAN';
        openSettings = Geolocator.openAppSettings;
      } else if (!serviceOn) {
        message = 'Lokasi perangkat (GPS) sedang dimatikan.';
        actionLabel = 'NYALAKAN';
        openSettings = Geolocator.openLocationSettings;
      }
    } catch (_) {
      // pesan default tetap dipakai
    }

    _toast(message, actionLabel: actionLabel, onAction: openSettings);
  }

  void _toast(
    String message, {
    String? actionLabel,
    Future<void> Function()? onAction,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          content: Text(
            message,
            style: GoogleFonts.poppins(fontSize: 13, height: 1.4),
          ),
          action: actionLabel == null
              ? null
              : SnackBarAction(
                  label: actionLabel,
                  onPressed: () => onAction?.call(),
                ),
        ),
      );
  }

  Future<void> _fetchAddress(LatLng pos) async {
    setState(() {
      _center = pos;
      _loading = true;
    });
    final result = await _controller.reverseGeocode(pos.latitude, pos.longitude);
    if (mounted) {
      setState(() {
        _hasAddress = result != null && result.full.isNotEmpty;
        _title = result?.label ?? 'Lokasi dipilih';
        // Kalau geocode gagal, koordinat tetap ditampilkan sebagai info —
        // tapi tombol konfirmasi dikunci supaya koordinat mentah tidak
        // pernah tersimpan sebagai "alamat".
        _address = result?.full ??
            '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          // ── PETA ──
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _center, zoom: 16),
            onMapCreated: (c) {
              _map = c;
              final pending = _pendingCamera;
              if (pending != null) {
                _pendingCamera = null;
                c.animateCamera(CameraUpdate.newLatLngZoom(pending, 17));
              }
            },
            onCameraMoveStarted: () => setState(() => _moving = true),
            onCameraMove: (p) => _center = p.target,
            onCameraIdle: () {
              setState(() => _moving = false);
              _debounce?.cancel();
              _debounce = Timer(
                const Duration(milliseconds: 500),
                () => _fetchAddress(_center),
              );
            },
            // Titik biru lokasi Google dimatikan: karena menempel pada
            // koordinat GPS, titik itu ikut bergeser setiap kali zoom
            // in/out — membingungkan di halaman pemilih peta. Posisi
            // pemakaian tetap terlihat lewat pin tengah, dan tombol
            // "lokasi saya" tetap bisa melompat ke GPS.
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            padding: const EdgeInsets.only(bottom: 260),
          ),

          // ── PIN TENGAH ──
          Positioned.fill(
            bottom: 260,
            child: IgnorePointer(
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  transform: Matrix4.translationValues(0, _moving ? -14 : 0, 0),
                  child: const Padding(
                    padding: EdgeInsets.only(bottom: 44),
                    child: Icon(Icons.location_on, size: 52, color: AppColors.primary),
                  ),
                ),
              ),
            ),
          ),

          // ── TOMBOL GPS ──
          Positioned(
            right: 14,
            bottom: 260 + 14,
            child: _RoundBtn(
              icon: Icons.my_location,
              busy: _locating,
              onTap: _goToMyLocation,
            ),
          ),

          // ── TOMBOL BACK ──
          Positioned(
            top: top + 12,
            left: 14,
            child: _RoundBtn(icon: Icons.arrow_back, onTap: () => Get.back()),
          ),

          // ── BOTTOM SHEET ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 20 + bottom),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 24,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3E8EE),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    'Konfirmasi Lokasi',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D2733),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE3E8EE)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE6F2FC),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.location_on,
                              color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _loading
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: LinearProgressIndicator(
                                    color: AppColors.primary,
                                    minHeight: 3,
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _title,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1D2733),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _address,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12.5,
                                        height: 1.45,
                                        color: const Color(0xFF6B7785),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!_loading && !_hasAddress) ...[
                    Text(
                      'Alamat untuk titik ini belum ditemukan — geser pin '
                      'sedikit lalu tunggu sebentar.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        height: 1.4,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.primary.withValues(alpha: 0.45),
                        disabledForegroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: (_loading || !_hasAddress)
                          ? null
                          : () => _controller.confirmMapAddress(
                                _address,
                                _center.latitude,
                                _center.longitude,
                              ),
                      child: Text(
                        'PILIH LOKASI INI',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _shadow = [
  BoxShadow(color: Color(0x38000000), blurRadius: 8, offset: Offset(0, 2)),
];

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  /// true → tampilkan spinner (lagi mengambil lokasi GPS).
  final bool busy;

  const _RoundBtn({required this.icon, required this.onTap, this.busy = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: _shadow,
        ),
        child: busy
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: AppColors.primary,
                ),
              )
            : Icon(icon, size: 21, color: const Color(0xFF1D2733)),
      ),
    );
  }
}
