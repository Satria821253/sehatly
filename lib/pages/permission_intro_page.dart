import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sehatly/app/config/prefs_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app/models/permission_item.dart';
import '../app/routes/app_routes.dart';
import '../app/controllers/permission_intro_controller.dart';
import '../widgets/permission_intro_widgets.dart';
import '../widgets/primary_button.dart';

class PermissionIntroPage extends GetView<PermissionIntroController> {
  const PermissionIntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        titleSpacing: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool(PrefsKeys.hasSeenIntro, true);
            Get.offAllNamed(AppRoutes.home);
          },
        ),
        title: Text(
          'Penggunaan Data & Izin',
          style: GoogleFonts.poppins(
            fontSize: 18,
            color: const Color(0xFF111827),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Scrollbar(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kami Menghargai Privasi Kamu',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pelajari cara Sehatly menggunakan izin aplikasi. '
                        'Kemudian, berikan persetujuan di bawah.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          height: 1.6,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 28),
                      for (final item in permissionItems) ...[
                        PermissionTile(item: item),
                        const SizedBox(height: 20),
                      ],
                      const SizedBox(height: 4),
                      const PrivacyFooter(),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Obx(
                () => PrimaryButton(
                  label: 'Saya Setuju',
                  onPressed: controller.isSaving.value ? null : controller.agree,
                  isLoading: controller.isSaving.value,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
