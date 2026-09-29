import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app/controllers/address_picker_controller.dart';
import '../app/config/prefs_keys.dart';
import '../app/services/reverse_geocoder.dart';
import '../app/theme/app_colors.dart';
import '../widgets/primary_button.dart';

class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  GoogleMapController? _map;

  /// Posisi cadangan: lokasi saat ini → alamat terakhir dipilih → pusat kota.
  static const _fallbackCenter = LatLng(-7.7956, 110.3695);

  /// Ukuran pin & tinggi area bottom sheet (dipakai bersama supaya sinkron).
  static const double _pinSize = 35;
  static const double _sheetHeight = 260;

  LatLng _center = _fallbackCenter;
  LatLng? _pendingCamera;
  String _title = 'Memuat lokasi...';
  String _address = '';

  /// true = alamat berasal dari reverse geocode (bukan koordinat mentah).
  bool _hasAddress = false;
  bool _loading = true;

  /// true = posisi awal sudah diketahui → peta boleh dirender.
  bool _ready = false;

  /// Sedang mengambil lokasi GPS (tombol "lokasi saya" menampilkan spinner).
  bool _locating = false;
  Timer? _debounce;

  // ── State pinch-zoom kustom (zoom selalu berpusat di tengah layar) ──
  final Map<int, Offset> _pointers = {};
  double _zoom = 16;
  double? _startDist;
  double _startZoom = 16;
  bool _multiTouch = false;

  final _controller = Get.find<AddressPickerController>();

  @override
  void initState() {
    super.initState();
    _initPosition();
  }

  /// Buka peta di lokasi Anda — bukan di koordinat hardcode.
  Future<void> _initPosition() async {
    final target = await _resolveInitialPosition();
    if (!mounted) return;
    setState(() {
      _center = target;
      _ready = true;
    });
    _moveCamera(target);
    await _fetchAddress(target);
  }

  Future<LatLng> _resolveInitialPosition() async {
    // 1) Lokasi saat ini (maks 6 detik).
    try {
      final coords = await currentCoordinates().timeout(
        const Duration(seconds: 6),
        onTimeout: () => null,
      );
      if (coords != null) return LatLng(coords.lat, coords.lng);
    } catch (e) {
      debugPrint('>>> ambil lokasi awal: $e');
    }

    // 2) Lokasi terakhir yang pernah dipilih user.
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble(PrefsKeys.selectedLat);
      final lng = prefs.getDouble(PrefsKeys.selectedLng);
      if (lat != null && lng != null) return LatLng(lat, lng);
    } catch (e) {
      debugPrint('>>> baca lokasi tersimpan gagal: $e');
    }

    // 3) Terakhir: pusat default.
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

  // ───────────────────────── PINCH ZOOM KUSTOM ─────────────────────────
  // Zoom bawaan Google Maps berpusat di titik jari, sehingga target kamera
  // (lokasi di bawah pin) ikut bergeser. Di sini zoom ditangani sendiri
  // dengan CameraUpdate.zoomTo, yang menjaga target kamera tetap.

  double _dist() {
    final p = _pointers.values.toList();
    return (p[0] - p[1]).distance;
  }

  void _onPointerDown(PointerDownEvent e) {
    _pointers[e.pointer] = e.position;
    if (_pointers.length == 2) {
      _startDist = _dist();
      _startZoom = _zoom;
      setState(() => _multiTouch = true); // 2 jari = zoom saja, tanpa geser
    }
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (!_pointers.containsKey(e.pointer)) return;
    _pointers[e.pointer] = e.position;
    if (_pointers.length == 2 && _startDist != null && _startDist! > 0) {
      final z = (_startZoom + math.log(_dist() / _startDist!) / math.ln2)
          .clamp(3.0, 21.0);
      _map?.moveCamera(CameraUpdate.zoomTo(z));
    }
  }

  void _onPointerUp(PointerEvent e) {
    _pointers.remove(e.pointer);
    if (_pointers.length < 2) {
      _startDist = null;
      if (_multiTouch) setState(() => _multiTouch = false);
    }
  }

  // ───────────────────────── LOKASI SAYA ─────────────────────────

  Future<void> _goToMyLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final coords = await currentCoordinates();
      if (!mounted) return;
      if (coords == null) {
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

  // ───────────────────────── PIN + BAYANGAN ─────────────────────────
  // Kotak berukuran (_pinSize x _pinSize*2), dipusatkan di layar peta.
  // Setengah atas = pin, ujung pin tepat di tengah kotak = titik kamera.
  // Lapisan (bawah → atas):
  //   1) bayangan oval di tanah (di ujung pin)
  //   2) bayangan siluet pin (blur, sedikit bergeser)
  //   3) pin asli
  Widget _buildPin() {
    return SizedBox(
      width: _pinSize,
      height: _pinSize * 2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1) Bayangan oval di tanah
          Positioned(
            left: _pinSize / 2 - 10,
            top: _pinSize - 3,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 1.5),
              child: Container(
                width: 20,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0x59000000),
                  borderRadius: BorderRadius.all(Radius.elliptical(10, 3)),
                ),
              ),
            ),
          ),

          // 2) Bayangan siluet pin (hitam transparan + blur)
          Positioned(
            left: 0,
            top: 0,
            child: Transform.translate(
              offset: const Offset(2, 3),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 2.2, sigmaY: 2.2),
                child: SvgPicture.asset(
                  'assets/svg/pin.svg',
                  width: _pinSize,
                  height: _pinSize,
                  fit: BoxFit.contain,
                  colorFilter: const ColorFilter.mode(
                    Color(0x66000000),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),

          // 3) Pin asli (crimson)
          Positioned(
            left: 0,
            top: 0,
            child: SvgPicture.asset(
              'assets/svg/pin.svg',
              width: _pinSize,
              height: _pinSize,
              fit: BoxFit.contain,
              colorFilter: const ColorFilter.mode(
                _crimson,
                BlendMode.srcIn,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          // ── PETA ──
          if (!_ready)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.white,
                child: Center(
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            )
          else
            Listener(
              onPointerDown: _onPointerDown,
              onPointerMove: _onPointerMove,
              onPointerUp: _onPointerUp,
              onPointerCancel: _onPointerUp,
              child: GoogleMap(
                initialCameraPosition:
                    CameraPosition(target: _center, zoom: 16),
                onMapCreated: (c) {
                  _map = c;
                  final pending = _pendingCamera;
                  if (pending != null) {
                    _pendingCamera = null;
                    c.animateCamera(CameraUpdate.newLatLngZoom(pending, 17));
                  }
                },
                onCameraMove: (p) {
                  _center = p.target;
                  _zoom = p.zoom; // simpan zoom terbaru untuk pinch kustom
                },
                onCameraIdle: () {
                  _debounce?.cancel();
                  _debounce = Timer(
                    const Duration(milliseconds: 500),
                    () => _fetchAddress(_center),
                  );
                },
                // Zoom bawaan dimatikan (pusatnya di jari). Zoom ditangani
                // Listener di atas → target kamera tidak berubah saat zoom.
                zoomGesturesEnabled: false,
                // Saat 2 jari (zoom), geser dimatikan agar target tetap.
                scrollGesturesEnabled: !_multiTouch,
                myLocationEnabled: true,
                myLocationButtonEnabled: false, // sudah ada tombol GPS sendiri
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
                padding: const EdgeInsets.only(bottom: _sheetHeight),
              ),
            ),

          // ── PIN TENGAH (dengan bayangan) ──
          // Digambar aplikasi (bukan marker Google), diam di tengah layar.
          // Kotak pin setinggi 2x ukuran pin, jadi ujung pin persis di
          // titik tengah = titik kamera.
          Positioned.fill(
            bottom: _sheetHeight,
            child: IgnorePointer(
              child: Center(child: _buildPin()),
            ),
          ),

          // ── TOMBOL GPS ──
          Positioned(
            right: 14,
            bottom: _sheetHeight + 14,
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
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3E8EE),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'Konfirmasi Lokasi',
                    style: GoogleFonts.poppins(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1D2733),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // ── DETAIL LOKASI ──
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(
                        color: AppColors.primary,
                        minHeight: 3,
                      ),
                    )
                  else ...[
                    Text(
                      _title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1D2733),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _address,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        height: 1.5,
                        color: const Color(0xFF6B7785),
                      ),
                    ),
                  ],
                  if (!_loading && !_hasAddress) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Alamat untuk titik ini belum ditemukan — geser pin '
                      'sedikit lalu tunggu sebentar.',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        height: 1.4,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Konfirmasi',
                    onPressed: (_loading || !_hasAddress)
                        ? null
                        : () => _controller.confirmMapAddress(
                              _address,
                              _center.latitude,
                              _center.longitude,
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

/// Warna pin tengah peta — pin.svg di-recolor crimson.
const _crimson = Color(0xFFE2195E);

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