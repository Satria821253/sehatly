import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../app/controllers/address_picker_controller.dart';
import '../app/services/initial_position.dart';
import '../app/services/reverse_geocoder.dart';
import '../app/theme/app_colors.dart';
import '../app/utils/pinch_zoom.dart';
import '../widgets/confirm_location_sheet.dart';
import '../widgets/error_message.dart';
import '../widgets/map_pin.dart';
import '../widgets/round_map_button.dart';

/// UI-nya dipecah ke file terpisah supaya halaman ini fokus ke alur:
///   * [MapPin]                 → pin tengah + bayangannya
///   * [ConfirmLocationSheet]   → sheet detail lokasi + tombol konfirmasi
///   * [RoundMapButton]         → tombol bundar (GPS, kembali)
///   * `resolveInitialPosition` → menentukan titik awal peta
///   * [PinchZoomController]    → zoom dua jari yang menjaga target tetap
class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  GoogleMapController? _map;

  LatLng _center = kFallbackCenter;
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

  /// Zoom dua jari berpusat di tengah layar (lihat pinch_zoom.dart).
  final _pinch = PinchZoomController();

  final _controller = Get.find<AddressPickerController>();

  @override
  void initState() {
    super.initState();
    _initPosition();
  }

  /// Buka peta di lokasi Anda — bukan di koordinat hardcode.
  Future<void> _initPosition() async {
    final target = await resolveInitialPosition();
    if (!mounted) return;
    setState(() {
      _center = target;
      _ready = true;
    });
    _moveCamera(target);
    await _fetchAddress(target);
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


  void _onPointerDown(PointerDownEvent e) {
    if (_pinch.pointerDown(e.pointer, e.position)) setState(() {});
  }

  void _onPointerMove(PointerMoveEvent e) {
    final zoom = _pinch.pointerMove(e.pointer, e.position);
    if (zoom != null) _map?.moveCamera(CameraUpdate.zoomTo(zoom));
  }

  void _onPointerUp(PointerEvent e) {
    if (_pinch.pointerUp(e.pointer)) setState(() {});
  }

  // ───────────────────────── LOKASI SAYA ─────────────────────────

  Future<void> _goToMyLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final coords = await currentCoordinates();
      if (!mounted) return;
      if (coords == null) {
        await showGpsUnavailableMessage(context);
        return;
      }
      final latlng = LatLng(coords.lat, coords.lng);
      _map?.animateCamera(CameraUpdate.newLatLngZoom(latlng, 17));
      await _fetchAddress(latlng);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  /// Ambil alamat untuk titik yang sedang dituju, lalu tampilkan di sheet.
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
                  _pinch.zoom = p.zoom; // simpan zoom terbaru untuk pinch
                },
                onCameraIdle: () {
                  _debounce?.cancel();
                  _debounce = Timer(
                    const Duration(milliseconds: 500),
                    () => _fetchAddress(_center),
                  );
                },
                zoomGesturesEnabled: false,
                // Saat 2 jari (zoom), geser dimatikan agar target tetap.
                scrollGesturesEnabled: !_pinch.multiTouch,
                myLocationEnabled: true,
                myLocationButtonEnabled: false, // sudah ada tombol GPS sendiri
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
                padding: const EdgeInsets.only(bottom: kConfirmSheetHeight),
              ),
            ),

          Positioned.fill(
            bottom: kConfirmSheetHeight,
            child: const IgnorePointer(child: Center(child: MapPin())),
          ),

          // ── TOMBOL GPS ──
          Positioned(
            right: 14,
            bottom: kConfirmSheetHeight + 14,
            child: RoundMapButton(
              icon: Icons.my_location,
              busy: _locating,
              onTap: _goToMyLocation,
            ),
          ),

          // ── TOMBOL BACK ──
          Positioned(
            top: top + 12,
            left: 14,
            child: RoundMapButton(icon: Icons.arrow_back, onTap: () => Get.back()),
          ),

          // ── BOTTOM SHEET ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ConfirmLocationSheet(
              title: _title,
              address: _address,
              loading: _loading,
              hasAddress: _hasAddress,
              onConfirm: () => _controller.confirmMapAddress(
                _address,
                _center.latitude,
                _center.longitude,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
