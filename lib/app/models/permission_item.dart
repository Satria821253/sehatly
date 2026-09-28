import 'package:flutter/material.dart';

class PermissionItem {
  const PermissionItem(this.icon, this.title, this.description);
  final IconData icon;
  final String title;
  final String description;
}

const permissionItems = [
  PermissionItem(
    Icons.location_on_outlined,
    'LOKASI',
    'Digunakan dalam **Toko Kesehatan** dan **Janji Temu Dokter** '
        'untuk memetakan faskes terdekat, meningkatkan akurasi lokasi, '
        'melacak pesanan.',
  ),
  PermissionItem(
    Icons.notifications_outlined,
    'NOTIFIKASI',
    'Digunakan untuk membagikan pembaruan penting tentang **jadwal konsultasi, '
        'pengingat minum obat, notifikasi tepat waktu dari dokter,** '
        'dan **informasi promo** yang relevan untukmu.',
  ),
  PermissionItem(
    Icons.photo_camera_outlined,
    'KAMERA',
    'Digunakan dalam **Chat dengan Dokter, Unggah Resep, Verifikasi Akun, '
        'Bantuan Pengguna** untuk mengambil '
        'dan mengirim foto secara langsung dari kamera perangkat.',
  ),
  PermissionItem(
    Icons.mic_none_outlined,
    'MIKROFON',
    'Digunakan untuk merekam audio secara langsung dalam sesi '
        '**telekonsultasi audio/video** bersama dokter atau tenaga kesehatan.',
  ),
  PermissionItem(
    Icons.wifi_outlined,
    'KEADAAN INTERNET & JARINGAN',
    'Digunakan untuk memastikan layanan aplikasi berjalan optimal dan dalam '
        '**portal pembayaran** untuk pencegahan penipuan serta validasi '
        'transaksi secara langsung.',
  ),
  PermissionItem(
    Icons.folder_outlined,
    'AKSES PENYIMPANAN',
    'Digunakan dalam **Chat dengan Dokter, Verifikasi Akun, Bantuan Pengguna** '
        'untuk mengunduh dan mengunggah '
        '**gambar, audio, video, dan dokumen** '
        'dari penyimpanan perangkat kamu.',
  ),
  PermissionItem(
    Icons.folder_shared_outlined,
    'PEMBAGIAN DENGAN PIHAK KETIGA',
    'Data pribadi yang diperoleh melalui izin sebagaimana dijelaskan di atas '
        '**hanya akan dibagikan dengan rekanan pihak ketiga Sehatly '
        'dan tidak akan digunakan untuk tujuan lain tanpa persetujuanmu.',
  ),
];
