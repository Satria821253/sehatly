import 'dart:async';
import 'dart:io';

/// Cek koneksi internet secara singkat lewat DNS lookup.
///
/// Dipakai untuk membedakan **"tidak ada hasil"** dengan **"tidak ada
/// internet"** sebelum menampilkan pesan ke user — misalnya saat pencarian
/// alamat kosong atau reverse geocode gagal.
///
/// Sengaja tidak memakai paket connectivity tambahan: cukup resolusi nama
/// host (timeout [timeout] per host), tanpa izin baru dan tanpa dependensi.
Future<bool> hasInternetConnection({
  Duration timeout = const Duration(seconds: 3),
}) async {
  for (final host in const ['dns.google', 'google.com']) {
    try {
      final addrs = await InternetAddress.lookup(host).timeout(timeout);
      if (addrs.isNotEmpty) return true;
    } catch (_) {
      // host pertama gagal → coba host berikutnya
    }
  }
  return false;
}
