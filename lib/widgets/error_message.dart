import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/theme/app_colors.dart';

/// Tampilan pesan error aplikasi — satu pintu untuk semua toast supaya
/// gayanya konsisten di seluruh halaman.
///
/// Tampilannya: **kartu putih melayang** (rounded 16, garis tipis + bayangan
/// halus), ikon peringatan dalam lingkaran merah muda di kiri, pesan berfont
/// Poppins, dan tombol aksi pil biru primary di kanan bawah — senada dengan
/// sheet konfirmasi.
///
/// Pemakaian:
/// ```dart
/// showErrorSnack(context, 'Gagal menyimpan alamat.');
///
/// showErrorSnack(context, 'GPS sedang dimatikan.',
///     icon: Icons.gps_off_rounded,
///     actionLabel: 'NYALAKAN',
///     onAction: Geolocator.openLocationSettings);
/// ```
void showErrorSnack(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
  IconData icon = Icons.error_outline_rounded,
}) {
  if (!context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.white,
        elevation: 4,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
        duration: const Duration(seconds: 5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x14000000)),
        ),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ikon peringatan dalam lingkaran
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 19, color: AppColors.error),
            ),
            const SizedBox(width: 12),

            // Pesan + tombol aksi
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      height: 1.45,
                      color: const Color(0xFF1D2733),
                    ),
                  ),
                  if (actionLabel != null) ...[
                    const SizedBox(height: 9),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Material(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            messenger.hideCurrentSnackBar();
                            onAction?.call();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            child: Text(
                              actionLabel,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
}

/// Handler untuk kondisi GPS yang tidak bisa diambil.
///
/// Mencari tahu penyebabnya — izin belum diberikan, layanan lokasi mati,
/// atau tidak diketahui — lalu menampilkan kartu pesan yang mudah
/// dipahami beserta jalan pintas ke pengaturan yang tepat.
Future<void> showGpsUnavailableMessage(BuildContext context) async {
  String message = 'Lokasi perangkat belum tersedia, coba lagi sebentar.';
  IconData icon = Icons.location_off_rounded;
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
      icon = Icons.lock_outline_rounded;
      actionLabel = 'BUKA PENGATURAN';
      openSettings = Geolocator.openAppSettings;
    } else if (!serviceOn) {
      message = 'Lokasi perangkat (GPS) sedang dimatikan.';
      icon = Icons.gps_off_rounded;
      actionLabel = 'NYALAKAN';
      openSettings = Geolocator.openLocationSettings;
    }
  } catch (_) {
    // pesan default tetap dipakai
  }

  if (!context.mounted) return;
  showErrorSnack(
    context,
    message,
    icon: icon,
    actionLabel: actionLabel,
    onAction: openSettings,
  );
}
