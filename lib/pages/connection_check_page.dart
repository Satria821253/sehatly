import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/controllers/connection_check_controller.dart';
import '../app/theme/app_colors.dart';
import '../widgets/lottie_loading.dart';
import '../widgets/primary_button.dart';

/// Layar pertama setelah splash bila internet jelek/matai — menahan user
/// di sini (bukan membiarkannya masuk home dalam kondisi kosong).
///
/// Isinya cuma animasi loading bawaan, satu baris penjelasan, dan tombol
/// **Coba Lagi**. Ditekan → animasi tetap berputar sambil koneksi dicek
/// ulang; kalau pulih, langsung menuju halaman tujuan.
class ConnectionCheckPage extends GetView<ConnectionCheckController> {
  const ConnectionCheckPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Obx(() {
          final checking = controller.checking.value;

          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LottieLoading(size: 240),
                  const SizedBox(height: 8),
                  Text(
                    checking
                        ? 'Memeriksa koneksi…'
                        : 'Koneksi internet terputus',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    checking
                        ? 'Tunggu sebentar, kami cek jaringan kamu lagi.'
                        : 'Koneksi internet kamu terputus. Cek kembali '
                              'jaringanmu, kemudian coba lagi.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      height: 1.55,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (!checking)
                    SizedBox(
                      width: 220,
                      child: PrimaryButton(
                        label: 'Coba Lagi',
                        onPressed: controller.check,
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
