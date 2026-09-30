// Alur offline: layar cek koneksi setelah splash, panel "Cek Jaringanmu"
// di dalam konten, dan mode offline halaman home (Lottie → panel → pulih
// sendiri saat internet kembali).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sehatly/app/controllers/connection_check_controller.dart';
import 'package:sehatly/app/controllers/home_controller.dart';
import 'package:sehatly/app/routes/app_routes.dart';
import 'package:sehatly/app/services/network_status.dart';
import 'package:sehatly/pages/connection_check_page.dart';
import 'package:sehatly/pages/home_page.dart';
import 'package:sehatly/widgets/lottie_loading.dart';
import 'package:sehatly/widgets/offline_panel.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _savedAddress =
    'Jl. Affandi CT X No.16, Santren, Caturtunggal, Kec. Depok, '
    'Kabupaten Sleman, DIY 55581, Indonesia';

void _tanpaAksi() {}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'selected_address': _savedAddress,
      'selected_lat': -7.7686282,
      'selected_lng': 110.3912216,
      'has_reached_home': true,
      'has_seen_intro': true,
    });
    // Jaringan diblokir di `flutter test`; tiap tes mengganti nilai ini
    // sesuai skenario (online/offline).
    connectivityProbe = ({
      Duration timeout = const Duration(seconds: 2),
    }) async => true;
  });

  tearDown(() {
    connectivityProbe = dnsConnectivityProbe;
    Get.reset();
  });

  group('Panel "Cek Jaringanmu"', () {
    testWidgets('judul, penjelasan, dan tombol Coba Lagi tampil', (
      tester,
    ) async {
      var ditekan = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: OfflinePanel(onRetry: () => ditekan = true)),
        ),
      );

      expect(find.text('Cek Jaringanmu'), findsOneWidget);
      expect(
        find.textContaining('Koneksi internet kamu terputus'),
        findsOneWidget,
      );
      expect(find.text('Coba Lagi'), findsOneWidget);

      await tester.tap(find.text('Coba Lagi'));
      expect(ditekan, isTrue, reason: 'tombol harus memanggil callback');
    });

    testWidgets('saat sedang memeriksa, tombol berubah jadi spinner', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflinePanel(onRetry: _tanpaAksi, checking: true),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Coba Lagi'), findsNothing);
    });
  });

  group('Layar cek koneksi setelah splash', () {
    testWidgets('koneksi mati → judul, penjelasan, dan Coba Lagi tampil', (
      tester,
    ) async {
      connectivityProbe = ({
        Duration timeout = const Duration(seconds: 2),
      }) async => false;
      Get.put(ConnectionCheckController());

      await tester.pumpWidget(
        const GetMaterialApp(home: ConnectionCheckPage()),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(LottieLoading), findsOneWidget);
      expect(find.text('Koneksi internet terputus'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
      // Saat idle, tidak ada tulisan "Memeriksa koneksi…".
      expect(find.text('Memeriksa koneksi…'), findsNothing);
    });

    testWidgets('koneksi pulih saat Coba Lagi → langsung masuk home', (
      tester,
    ) async {
      var online = false;
      connectivityProbe = ({
        Duration timeout = const Duration(seconds: 2),
      }) async => online;
      Get.put(ConnectionCheckController());

      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: AppRoutes.connectionCheck,
          getPages: [
            GetPage(
              name: AppRoutes.connectionCheck,
              page: () => const ConnectionCheckPage(),
            ),
            GetPage(
              name: AppRoutes.home,
              page: () => const Scaffold(body: Text('BERANDA')),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Coba Lagi'), findsOneWidget);

      // Internet pulih lalu user menekan Coba Lagi.
      online = true;
      await tester.tap(find.text('Coba Lagi'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('BERANDA'), findsOneWidget);
    });

    testWidgets('Coba Lagi masih gagal → lanjut ke home mode offline', (
      tester,
    ) async {
      connectivityProbe = ({
        Duration timeout = const Duration(seconds: 2),
      }) async => false;
      Get.put(ConnectionCheckController());
      Get.put(HomeController());

      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: AppRoutes.connectionCheck,
          getPages: [
            GetPage(
              name: AppRoutes.connectionCheck,
              page: () => const ConnectionCheckPage(),
            ),
            GetPage(name: AppRoutes.home, page: () => const HomePage()),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Coba Lagi'), findsOneWidget);

      // Tekan Coba Lagi tapi internet masih mati → tidak ditahan di layar
      // cek koneksi, langsung masuk home dalam mode offline.
      await tester.tap(find.text('Coba Lagi'));
      await tester.pump();
      // Tunggu animasi transisi halaman selesai (halaman cek koneksi masih
      // berada di pohon widget selama transisi).
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(LottieLoading), findsOneWidget);
      expect(find.text('Cek Jaringanmu'), findsNothing); // masih masa tenggang

      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Cek Jaringanmu'), findsOneWidget);
      expect(find.text(_savedAddress), findsNothing); // isi disembunyikan

      // Pulihkan koneksi supaya timer polling tidak tertinggal di akhir tes.
      connectivityProbe = ({
        Duration timeout = const Duration(seconds: 2),
      }) async => true;
      await Get.find<HomeController>().retryConnection();
      await tester.pump();

      expect(find.text('Cek Jaringanmu'), findsNothing);
      expect(find.text(_savedAddress), findsOneWidget);
    });
  });

  group('Home mode offline', () {
    testWidgets(
      'Lottie dulu → panel Cek Jaringanmu → internet pulih → isi tampil',
      (tester) async {
        var online = false;
        connectivityProbe = ({
          Duration timeout = const Duration(seconds: 2),
        }) async => online;

        Get.put(HomeController());
        await tester.pumpWidget(const GetMaterialApp(home: HomePage()));
        await tester.pump();

        // Baru beberapa detik → hanya Lottie, panel belum muncul.
        expect(find.byType(LottieLoading), findsOneWidget);
        expect(find.text('Cek Jaringanmu'), findsNothing);

        // Masa tenggang lewat (3 detik) → panel "Cek Jaringanmu" tampil.
        await tester.pump(const Duration(seconds: 3));
        expect(find.text('Cek Jaringanmu'), findsOneWidget);
        expect(find.text('Coba Lagi'), findsOneWidget);
        // Isi halaman disembunyikan selama offline.
        expect(find.text(_savedAddress), findsNothing);

        // Internet pulih → tekan Coba Lagi → isi kembali tampil.
        online = true;
        await Get.find<HomeController>().retryConnection();
        await tester.pump();

        expect(find.text('Cek Jaringanmu'), findsNothing);
        expect(find.text(_savedAddress), findsOneWidget);
        expect(find.byType(LottieLoading), findsNothing);
      },
    );
  });
}
