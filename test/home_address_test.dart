import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sehatly/app/controllers/home_controller.dart';
import 'package:sehatly/app/routes/app_routes.dart';
import 'package:sehatly/app/services/network_status.dart';
import 'package:sehatly/pages/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _fullAddress =
    'Jl. Affandi CT X No.16, Santren, Caturtunggal, Kec. Depok, '
    'Kabupaten Sleman, DIY 55581, Indonesia';
const _shortAddress = 'Jl. Affandi CT X No.16, Santren';

/// Pump halaman home dengan alamat tersimpan (atau kosong).
Future<void> _pumpHome(WidgetTester tester, {String? savedAddress}) async {
  final values = <String, Object>{};
  if (savedAddress != null) {
    values['selected_address'] = savedAddress;
    values['selected_lat'] = -7.7686282;
    values['selected_lng'] = 110.3912216;
  }
  SharedPreferences.setMockInitialValues(values);

  Get.reset();
  Get.put(HomeController());

  await tester.pumpWidget(
    GetMaterialApp(
      initialRoute: AppRoutes.home,
      getPages: [
        GetPage(name: AppRoutes.home, page: () => const HomePage()),
        // Halaman picker di-stub supaya test tidak menyentuh GPS/network.
        GetPage(
          name: AppRoutes.addressPicker,
          page: () => const Scaffold(body: Text('PILIH ALAMAT')),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    // Jaringan diblokir di `flutter test` → HomeController akan selalu
    // masuk mode offline. Beri tahu tes bahwa koneksi tersedia supaya isi
    // halaman tampil seperti pada perangkat sungguhan.
    connectivityProbe = ({
      Duration timeout = const Duration(seconds: 2),
    }) async => true;
  });

  tearDown(() {
    connectivityProbe = dnsConnectivityProbe;
    Get.reset();
  });

  testWidgets('Alamat tersimpan tampil di kartu & chip lokasi', (tester) async {
    await _pumpHome(tester, savedAddress: _fullAddress);

    // Alamat lengkap tampil.
    expect(find.text(_fullAddress), findsOneWidget);
    // Chip di pojok kanan atas memakai alamat ringkas.
    expect(find.text(_shortAddress), findsOneWidget);
    // Koordinat ikut tampil.
    expect(
      find.textContaining('Koordinat -7.76863, 110.39122'),
      findsOneWidget,
    );

    // Posisi chip: di sebelah kanan dan di bagian atas layar.
    final screen = tester.getSize(find.byType(GetMaterialApp));
    final chip = tester.getRect(find.byKey(const Key('home_location_chip')));
    expect(
      chip.center.dx,
      greaterThan(screen.width / 2),
      reason: 'chip lokasi harus di pojok kanan',
    );
    expect(chip.top, lessThan(120), reason: 'chip lokasi harus di bagian atas');

    // Tutup controller supaya timer polling tidak tertinggal di akhir tes.
    // (Get.reset() tidak memanggil onClose — harus Get.delete.)
    Get.delete<HomeController>(force: true);
  });

  testWidgets('Belum ada alamat → chip mengajak memilih alamat', (
    tester,
  ) async {
    await _pumpHome(tester);

    expect(find.text('Pilih alamat'), findsOneWidget);
    expect(find.textContaining('Belum ada alamat'), findsOneWidget);

    // Tutup controller supaya timer polling tidak tertinggal di akhir tes.
    // (Get.reset() tidak memanggil onClose — harus Get.delete.)
    Get.delete<HomeController>(force: true);
  });

  testWidgets('Ketuk chip lokasi → sheet pilih alamat terbuka & bisa ditutup', (
    tester,
  ) async {
    await _pumpHome(tester, savedAddress: _fullAddress);

    await tester.tap(find.byKey(const Key('home_location_chip')));
    await tester.pumpAndSettle();

    // Berupa bottom sheet (bukan halaman), jadi panelnya bisa digeser ke
    // bawah untuk menutup.
    expect(find.text('Pilih Alamat'), findsOneWidget);
    // Pegangan garis di atas sheet berfungsi sebagai tombol tutup.
    expect(find.byKey(const Key('address_picker_handle')), findsOneWidget);

    // Ketuk pegangan → sheet tertutup tanpa tombol back, alamat tetap tampil.
    await tester.tap(find.byKey(const Key('address_picker_handle')));
    await tester.pumpAndSettle();
    expect(find.text(_fullAddress), findsOneWidget);

    // Tutup controller supaya timer polling tidak tertinggal di akhir tes.
    // (Get.reset() tidak memanggil onClose — harus Get.delete.)
    Get.delete<HomeController>(force: true);
  });
}
