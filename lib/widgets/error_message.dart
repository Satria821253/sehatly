import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tampilan pesan error aplikasi — satu pintu untuk semua toast/snackbar
/// supaya gaya menampilkan error konsisten di seluruh halaman.
///
/// Pemakaian:
/// ```dart
/// showErrorSnack(context, 'Gagal menyimpan alamat.');
///
/// showErrorSnack(context, 'Izin lokasi belum diberikan.',
///     actionLabel: 'BUKA PENGATURAN',
///     onAction: Geolocator.openAppSettings);
/// ```
void showErrorSnack(
  BuildContext context,
  String message, {
  String? actionLabel,
  Future<void> Function()? onAction,
}) {
  if (!context.mounted) return;

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

/// Handler untuk kondisi GPS yang tidak bisa diambil.
///
/// Mencari tahu penyebabnya — izin belum diberikan, layanan lokasi mati,
/// atau tidak diketahui — lalu menampilkan pesan yang mudah dipahami
/// beserta jalan pintas ke pengaturan yang tepat.
Future<void> showGpsUnavailableMessage(BuildContext context) async {
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

  if (!context.mounted) return;
  showErrorSnack(
    context,
    message,
    actionLabel: actionLabel,
    onAction: openSettings,
  );
}
