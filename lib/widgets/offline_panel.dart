import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/theme/app_colors.dart';
import 'primary_button.dart';

/// Panel "Cek Jaringanmu" — pesan offline yang tampil **di dalam konten**
/// (bukan toast yang menutupi, bukan layar penuh yang mengunci navigasi).
///
/// Dipakai di halaman home (mode offline) dan halaman pilih alamat.
/// Saat internet pulih panel ini hilang sendiri, tapi user tetap bisa
/// menekan "Coba Lagi" untuk mengecek sekarang.
class OfflinePanel extends StatelessWidget {
  const OfflinePanel({super.key, required this.onRetry, this.checking = false});

  /// Dijalankan saat tombol "Coba Lagi" ditekan.
  final VoidCallback onRetry;

  /// true → tombol menampilkan spinner (sedang memeriksa koneksi).
  final bool checking;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ikon jaringan mati dalam lingkaran lembut.
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 30,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Cek Jaringanmu',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Koneksi internet kamu terputus. Cek kembali jaringanmu, '
              'kemudian coba lagi.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                height: 1.55,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 220,
              child: PrimaryButton(
                label: 'Coba Lagi',
                isLoading: checking,
                onPressed: checking ? null : onRetry,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
