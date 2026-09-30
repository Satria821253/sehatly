// Alur onboarding: splash -> halaman izin lokasi -> pilih alamat.
//
// Catatan: halaman "permission intro" tidak dilewati di sini karena route
// berikutnya dari splash ditentukan oleh
// LocationPermissionController.nextRoute() → pada first launch (izin belum
// ada & alamat manual belum dipilih) selalu ke halaman izin lokasi.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sehatly/app/controllers/home_controller.dart';
import 'package:sehatly/app/services/network_status.dart';
import 'package:sehatly/main.dart';

const MethodChannel _geolocatorChannel = MethodChannel(
  'flutter.baseflow.com/geolocator',
);

const MethodChannel _packageInfoChannel = MethodChannel(
  'dev.fluttercommunity.plus/package_info',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Jaringan diblokir di `flutter test` → splash akan selalu menganggap
    // internet mati dan menahan user di layar "Cek Jaringanmu". Beri tahu
    // tes bahwa koneksi tersedia supaya alur onboarding jalan normal.
    connectivityProbe = ({
      Duration timeout = const Duration(seconds: 2),
    }) async => true;
    // Geolocator tidak punya platform-side di test -> beri mock supaya
    // checkPermission() segera membalas (status: belum diizinkan).
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_geolocatorChannel, (call) async {
          switch (call.method) {
            case 'checkPermission':
              return 0; // LocationPermission.denied
            case 'isLocationServiceEnabled':
              return true;
            case 'openAppSettings':
            case 'openLocationSettings':
              return true;
            default:
              return null;
          }
        });

    // Splash memanggil PackageInfo.fromPlatform() untuk menampilkan versi.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_packageInfoChannel, (call) async {
          if (call.method == 'getAll') {
            return {
              'appName': 'Sehatly',
              'packageName': 'com.sehatly.app',
              'version': '1.0.0',
              'buildNumber': '1',
            };
          }
          return null;
        });
  });

  tearDown(() {
    connectivityProbe = dnsConnectivityProbe;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_geolocatorChannel, null);
    messenger.setMockMethodCallHandler(_packageInfoChannel, null);
  });

  testWidgets('Splash -> halaman izin lokasi -> pilih alamat', (tester) async {
    await tester.pumpWidget(const MyApp());
    // PostFrameCallback splash menunda animasi 300ms → jalankan dulu.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    // Selesaikan animasi splash (durasi 2200ms) supaya tombol sudah stabil.
    await tester.pump(const Duration(milliseconds: 2300));
    expect(find.text('SEHAT LEBIH MUDAH!'), findsOneWidget);

    // Dari splash ke halaman izin lokasi (izin belum diberikan).
    // Tap ke InkWell (bukan teksnya) supaya hit test tepat sasaran.
    await tester.tap(find.widgetWithText(InkWell, 'SEHAT LEBIH MUDAH!'));
    await tester.pumpAndSettle();
    expect(find.text('AKTIFKAN LOKASI'), findsOneWidget);
    expect(find.text('TENTUKAN ALAMAT'), findsOneWidget);

    // Buka sheet pemilihan alamat.
    await tester.tap(find.text('TENTUKAN ALAMAT'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih Alamat'), findsOneWidget);

    // Siram timer auto-navigate splash yang masih tertunda.
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Pilih Alamat'), findsOneWidget);
  });

  testWidgets('Izin lokasi diberikan → koordinat tersimpan & masuk home', (
    tester,
  ) async {
    // Ukuran layar seperti HP — layout halaman izin meluber di 800x600
    // (bawaan test) dan tombolnya jadi tidak bisa diketuk.
    tester.view.physicalSize = const Size(414, 896);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    // Izin awal "ditolak" supaya tombol AKTIFKAN LOKASI memunculkan dialog
    // sistem; setelah dijawab user → whileInUse (2), GPS punya koordinat.
    var permission = 0; // LocationPermission.denied
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_geolocatorChannel, (call) async {
          switch (call.method) {
            case 'checkPermission':
              return permission;
            case 'requestPermission':
              permission = 2; // LocationPermission.whileInUse
              return permission;
            case 'isLocationServiceEnabled':
              return true;
            case 'getCurrentPosition':
              return {'latitude': -7.7686282, 'longitude': 110.3912216};
            case 'openAppSettings':
            case 'openLocationSettings':
              return true;
            default:
              return null;
          }
        });

    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 2300));

    await tester.tap(find.widgetWithText(InkWell, 'SEHAT LEBIH MUDAH!'));
    await tester.pumpAndSettle();
    expect(find.text('AKTIFKAN LOKASI'), findsOneWidget);

    await tester.tap(find.text('AKTIFKAN LOKASI'));
    // Izin → ambil GPS → reverse geocode → pindah ke home. Beberapa siklus
    // pump karena semua itu berjalan asinkron.
    for (var i = 0; i < 4; i++) {
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pumpAndSettle();

    // Koordinat GPS wajib tersimpan.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getDouble('selected_lat'), -7.7686282);
    expect(prefs.getDouble('selected_lng'), 110.3912216);

    // Halaman home terbuka dan kartu alamatnya tampil.
    expect(find.text('Alamat terpilih'), findsOneWidget);
    expect(
      find.textContaining('Koordinat -7.76863, 110.39122'),
      findsOneWidget,
    );
    // Reverse geocode butuh jaringan (diblokir test) → lookup dianggap
    // gagal dan kartu mengajak memilih alamat manual, bukan menampilkan
    // "Menentukan alamat…" seolah prosesnya masih berjalan tanpa ujung.
    expect(find.textContaining('Alamat belum ditemukan'), findsWidgets);

    // Tutup controller supaya timer polling tidak tertinggal di akhir tes.
    // (Get.reset() tidak memanggil onClose — harus Get.delete.)
    Get.delete<HomeController>(force: true);
  });
}
