import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/controllers/location_permission_controller.dart';
import '../app/theme/app_colors.dart';
import '../widgets/primary_button.dart';
import '../widgets/outline_button.dart';
import 'address_picker_page.dart' show AddressPickerSheet;

/// Halaman izin lokasi — tampil setelah splash pada first launch,
/// atau saat izin lokasi belum diberikan.
class LocationPermissionPage extends GetView<LocationPermissionController> {
  const LocationPermissionPage({super.key});

  static const String _illustration = 'assets/images/wherelocation.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.white, Colors.white, Colors.transparent],
                stops: [0.0, 0.15, 0.75, 1.0],
              ).createShader(rect),
              blendMode: BlendMode.dstIn,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF7F2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Image.asset(
                  _illustration,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 44),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Text(
                'Kami membutuhkan lokasi untuk menampilkan layanan '
                'dan fasilitas kesehatan terdekat',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF1F2937),
                  fontSize: 16,
                  height: 1.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(flex: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  Obx(() => PrimaryButton(
                    label: controller.isPermanentlyDenied.value
                        ? 'PERGI KE PENGATURAN'
                        : 'AKTIFKAN LOKASI',
                    isLoading: controller.isLoading.value,
                    onPressed: controller.isLoading.value
                        ? null
                        : controller.activateLocation,
                  )),
                  const SizedBox(height: 16),
                  Text(
                    'ATAU',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[500],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlineButton(
                    label: 'TENTUKAN ALAMAT',
                    onPressed: () => AddressPickerSheet.show(context),
                  ),
                 const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

