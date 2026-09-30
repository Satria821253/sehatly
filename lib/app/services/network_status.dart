import 'dart:async';
import 'dart:io';

/// Tipe pemeriksa koneksi internet.
///
/// Berbentuk fungsi (bukan `Future<bool>` biasa) supaya bisa **diganti saat
/// pengujian** lewat [connectivityProbe] — lihat catatannya di sana.
typedef ConnectivityProbe = Future<bool> Function({Duration timeout});

/// Pemeriksa sungguhan: resolusi nama dua host **bersamaan** dengan
/// [timeout] bawaan 2 detik.
///
/// Saat jaringan benar-benar putus, pemanggil hanya menunggu ±2 detik
/// (bukan 6 detik berurutan) sebelum tahu bahwa internet mati.
Future<bool> dnsConnectivityProbe({
  Duration timeout = const Duration(seconds: 2),
}) async {
  final probes = [
    for (final host in const ['dns.google', 'google.com'])
      InternetAddress.lookup(host)
          .timeout(timeout)
          .then((addrs) => addrs.isNotEmpty)
          .catchError((_) => false),
  ];

  final results = await Future.wait(probes);
  return results.contains(true);
}

/// Pemeriksa koneksi yang dipakai seluruh aplikasi.
///
/// Pengujian mengganti nilai ini (mis. `({timeout}) async => true`) karena
/// lingkungan `flutter test` memblokir jaringan — tanpa penggantian, setiap
/// alur yang mengecek koneksi akan selalu menganggap internet mati. Selalu
/// kembalikan ke [dnsConnectivityProbe] di `tearDown` supaya tes lain tidak
/// ikut terpengaruh.
ConnectivityProbe connectivityProbe = dnsConnectivityProbe;

/// Cek koneksi internet secara singkat lewat [connectivityProbe].
///
/// Dipakai untuk membedakan **"tidak ada hasil"** dengan **"tidak ada
/// internet"** sebelum menampilkan pesan ke user — misalnya saat pencarian
/// alamat kosong, reverse geocode gagal, atau menahan user di layar
/// "Cek Jaringanmu" setelah splash.
///
/// Sengaja tidak memakai paket connectivity tambahan: cukup resolusi nama
/// host, tanpa izin baru dan tanpa dependensi.
Future<bool> hasInternetConnection({
  Duration timeout = const Duration(seconds: 2),
}) {
  return connectivityProbe(timeout: timeout);
}
