import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/controllers/location_permission_controller.dart';
import '../app/theme/app_colors.dart';
import '../widgets/primary_button.dart';
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
                    onPressed: controller.activateLocation,
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
                  _OutlineActionButton(
                    label: 'TENTUKAN ALAMAT',
                    onPressed: () => AddressPickerSheet.show(context),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Kamu tetap bisa mengubah izin lokasi\nkapan saja di Pengaturan aplikasi.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.grey[500],
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tombol sekunder: outline biru, teks biru.
class _OutlineActionButton extends StatelessWidget {
  const _OutlineActionButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: AppColors.primary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
