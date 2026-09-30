import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/theme/app_colors.dart';
import 'primary_button.dart';

/// Tinggi bottom sheet "Konfirmasi Lokasi".
///
/// Dipakai halaman peta untuk mengatur padding peta, posisi pin, dan
/// posisi tombol supaya semuanya sinkron dengan sheet ini.
const double kConfirmSheetHeight = 260;

/// Bottom sheet di bawah peta berisi detail lokasi terakhir dan tombol
/// konfirmasi (memakai [PrimaryButton] bawaan tema aplikasi).
class ConfirmLocationSheet extends StatelessWidget {
  const ConfirmLocationSheet({
    super.key,
    required this.title,
    required this.address,
    required this.loading,
    required this.hasAddress,
    required this.onConfirm,
    this.offline = false,
  });

  /// Nama lokasi (hasil reverse geocode).
  final String title;

  /// Alamat lengkap — atau koordinat mentah bila geocode gagal.
  final String address;

  /// true → alamat sedang diambil (tampilkan garis progress).
  final bool loading;

  /// false → alamat belum ditemukan (catatan tampil, tombol dikunci).
  final bool hasAddress;

  /// true → penyebabnya internet mati, bukan titik yang tidak dikenali
  /// (catatannya jadi berbeda supaya tidak menyesatkan).
  final bool offline;

  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Container(
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
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(
                color: AppColors.primary,
                minHeight: 3,
              ),
            )
          else ...[
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1D2733),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              address,
              style: GoogleFonts.poppins(
                fontSize: 14,
                height: 1.5,
                color: const Color(0xFF6B7785),
              ),
            ),
          ],
          if (!loading && !hasAddress) ...[
            const SizedBox(height: 10),
            Text(
              offline
                  ? 'Tidak ada koneksi internet — alamat tidak bisa '
                      'diambil. Periksa Wi-Fi/data Anda, lalu geser pin '
                      'untuk mencoba lagi.'
                  : 'Alamat untuk titik ini belum ditemukan — geser pin '
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
            onPressed: (loading || !hasAddress) ? null : onConfirm,
          ),
        ],
      ),
    );
  }
}
