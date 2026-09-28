import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../app/controllers/address_picker_controller.dart';
import '../app/theme/app_colors.dart';
import '../widgets/primary_button.dart';

class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  final _mapController = MapController();
  LatLng _center = const LatLng(-7.7956, 110.3695); // Yogyakarta default
  String? _address;
  bool _loading = false;
  Timer? _debounce;

  final _controller = Get.find<AddressPickerController>();

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if (!hasGesture) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () => _fetchAddress(camera.center));
  }

  Future<void> _fetchAddress(LatLng pos) async {
    setState(() {
      _center = pos;
      _loading = true;
      _address = null;
    });
    final result = await _controller.reverseGeocode(pos.latitude, pos.longitude);
    if (mounted) {
      setState(() {
        _address = result?.full;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 15,
              onPositionChanged: _onPositionChanged,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.sehatly',
              ),
            ],
          ),
          // Pin tengah
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_pin, color: AppColors.primary, size: 48),
                SizedBox(height: 24),
              ],
            ),
          ),
          // Tombol back
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
                  onPressed: () => Get.back(),
                ),
              ),
            ),
          ),
          // Panel bawah
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Lokasi dipilih',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (_loading)
                    const LinearProgressIndicator()
                  else
                    Text(
                      _address ?? 'Geser peta untuk memilih lokasi',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'PILIH LOKASI INI',
                    onPressed: () {
                      if (_address != null) {
                        _controller.confirmMapAddress(
                          _address!,
                          _center.latitude,
                          _center.longitude,
                        );
                      }
                    },
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
