import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:sehatly/app/theme/app_colors.dart';
import 'package:sehatly/widgets/error_message.dart';

/// Preview visual kartu pesan error — golden test.
///
/// Me-render widget `showErrorSnack` yang asli (bukan mock) di atas tiruan
/// layar HP, lalu menyimpannya sebagai PNG supaya tampilannya bisa dilihat
/// tanpa menjalankan aplikasi di perangkat.
///
/// Huruf Poppins dimuat dari aset aplikasi (`assets/fonts/`), jadi teks pada
/// gambar sama persis dengan tampilan di HP.
///
/// Perbarui gambarnya setelah gaya pesan berubah:
/// ```bash
/// flutter test --update-goldens test/card_preview_test.dart
/// ```
/// Hasil: `test/goldens/kartu_*.png`.

/// Muat font Material Icons — di dalam test ikon (mis. `wifi_off`) tidak
/// tampil karena font bawaan test hanya berisi kotak.
Future<void> _loadIcons() async {
  // Path font ikon ada di instalasi Flutter. Di dalam `flutter test`,
  // executable-nya adalah flutter_tester.exe (bukan dart.exe), jadi cari
  // dengan menaiki direktori sampai ketemu berkas font-nya.
  const candidates = [
    '/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
    '/bin/cache/pkg/sky_engine/assets/MaterialIcons-Regular.otf',
  ];
  var dir = File(Platform.resolvedExecutable).parent;
  for (var level = 0; level < 8; level++) {
    for (final relative in candidates) {
      final file = File('${dir.path}$relative');
      if (!file.existsSync()) continue;
      final bytes = await file.readAsBytes();
      final data = ByteData.view(
        bytes.buffer,
        bytes.offsetInBytes,
        bytes.lengthInBytes,
      );
      await (FontLoader('MaterialIcons')..addFont(Future.value(data))).load();
      return;
    }
    dir = dir.parent;
  }
}

/// Layar tiruan berukuran HP dengan header + panel bawah, supaya posisi
/// kartu terlihat seperti di aplikasi asli (melayang di atas sheet).
Widget _host(String label, void Function(BuildContext) show) {
  return MaterialApp(
    home: Scaffold(
      backgroundColor: const Color(0xFFE8EDF2),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: AppColors.primary,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  'Sehatly — preview kartu error',
                  // Pakai GoogleFonts persis seperti aplikasi aslinya (font
                  // bawaan test hanya menghasilkan kotak).
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Builder(
                builder: (context) => ElevatedButton(
                  key: const Key('trigger'),
                  onPressed: () => show(context),
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Tiruan sheet konfirmasi (lokasi kartu di layar HP).
          Container(
            height: 230,
            color: AppColors.white,
            padding: const EdgeInsets.all(18),
            child: Text(
              'Konfirmasi Lokasi',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.dark,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Tekan tombol pemicu, tunggu animasi kartu selesai, simpan sebagai emas.
Future<void> _capture(
  WidgetTester tester,
  String label,
  void Function(BuildContext) show,
  String golden,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_host(label, show));
  await tester.tap(find.byKey(const Key('trigger')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400)); // animasi masuk

  await expectLater(
    find.byType(Scaffold),
    matchesGoldenFile(golden),
  );
}

void main() {
  setUpAll(_loadIcons);

  testWidgets('kartu tidak ada internet', (tester) async {
    await _capture(
      tester,
      'Cari alamat (offline)',
      showNoInternetSnack,
      'goldens/kartu_tidak_ada_internet.png',
    );
  });

  testWidgets('kartu gagal simpan alamat', (tester) async {
    await _capture(
      tester,
      'Pilih alamat',
      showAddressSaveFailedSnack,
      'goldens/kartu_gagal_simpan.png',
    );
  });

  testWidgets('kartu gagal muat alamat', (tester) async {
    await _capture(
      tester,
      'Buka beranda',
      showAddressLoadFailedSnack,
      'goldens/kartu_gagal_muat.png',
    );
  });

  testWidgets('kartu izin lokasi belum diberikan', (tester) async {
    await _capture(
      tester,
      'Tombol lokasi saya',
      (context) => showErrorSnack(
        context,
        'Izin lokasi belum diberikan — beri izin dulu supaya tombol '
            'ini bisa membawa peta ke lokasi Anda.',
        icon: Icons.lock_outline_rounded,
        actionLabel: 'BUKA PENGATURAN',
        onAction: () {},
      ),
      'goldens/kartu_izin_lokasi.png',
    );
  });

  testWidgets('kartu GPS dimatikan', (tester) async {
    await _capture(
      tester,
      'Tombol lokasi saya',
      (context) => showErrorSnack(
        context,
        'Lokasi perangkat (GPS) sedang dimatikan.',
        icon: Icons.gps_off_rounded,
        actionLabel: 'NYALAKAN',
        onAction: () {},
      ),
      'goldens/kartu_gps_mati.png',
    );
  });
}
