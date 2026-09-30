// Verifikasi UI halaman pilih alamat:
//  1. semua data hasil pencarian benar-benar tampil (judul + detail)
//  2. item tanpa detail tidak menampilkan subtitle kosong
//  3. saat loading tampil shimmer
//  4. memilih hasil → alamat tersimpan ke SharedPreferences & pindah home

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

import 'package:sehatly/app/config/prefs_keys.dart';
import 'package:sehatly/app/controllers/address_picker_controller.dart';
import 'package:sehatly/app/models/address_result.dart';
import 'package:sehatly/app/routes/app_routes.dart';
import 'package:sehatly/pages/address_picker_page.dart';

AddressResult _result({
  required String main,
  String detail = '',
  String full = '',
}) => AddressResult(
  label: main,
  main: main,
  detail: detail,
  full: full.isEmpty ? main : full,
);

Widget _app() => GetMaterialApp(
  initialRoute: AppRoutes.addressPicker,
  getPages: [
    GetPage(
      name: AppRoutes.addressPicker,
      page: () => const AddressPickerPage(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const Scaffold(body: Text('HALAMAN HOME')),
    ),
  ],
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    if (Get.isRegistered<AddressPickerController>()) {
      Get.delete<AddressPickerController>();
    }
  });

  testWidgets('Hasil pencarian tampil semua: judul + detail', (tester) async {
    final c = Get.put(AddressPickerController());
    c.results.assignAll([
      _result(
        main: 'Indomaret Kaliurang KM10',
        detail: 'Jalan Kaliurang, Sleman, Daerah Istimewa Yogyakarta',
      ),
      _result(
        main: 'Rumah Sakit Jih',
        detail: 'Jalan Kaliurang, Ngaglik, Sleman',
        full: 'Jalan Kaliurang No.1, Sleman, DIY',
      ),
    ]);

    await tester.pumpWidget(_app());
    await tester.pump();

    expect(find.text('Indomaret Kaliurang KM10'), findsOneWidget);
    expect(
      find.text('Jalan Kaliurang, Sleman, Daerah Istimewa Yogyakarta'),
      findsOneWidget,
    );
    expect(find.text('Rumah Sakit Jih'), findsOneWidget);
    expect(find.text('Jalan Kaliurang, Ngaglik, Sleman'), findsOneWidget);
    // Ikon penanda tiap hasil ikut tampil.
    expect(find.byIcon(Icons.location_on), findsNWidgets(2));
  });

  testWidgets('Item tanpa detail tidak menampilkan subtitle kosong', (
    tester,
  ) async {
    final c = Get.put(AddressPickerController());
    c.results.assignAll([_result(main: 'Puskesmas Pakem')]);

    await tester.pumpWidget(_app());
    await tester.pump();

    expect(find.text('Puskesmas Pakem'), findsOneWidget);

    // Subtitle harus null (bukan teks kosong) bila detail tidak ada.
    final tile = tester.widget<ListTile>(
      find.ancestor(
        of: find.text('Puskesmas Pakem'),
        matching: find.byType(ListTile),
      ),
    );
    expect(tile.subtitle, isNull);
    expect(tile.enabled, isTrue);
  });

  testWidgets('Saat loading menampilkan shimmer, bukan daftar kosong', (
    tester,
  ) async {
    final c = Get.put(AddressPickerController());
    c.isLoading.value = true;

    await tester.pumpWidget(_app());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(Shimmer), findsOneWidget);
    c.isLoading.value = false;
    await tester.pump();
    expect(find.byType(Shimmer), findsNothing);
  });

  testWidgets('Memilih hasil → alamat tersimpan & pindah ke home', (
    tester,
  ) async {
    final c = Get.put(AddressPickerController());
    c.results.assignAll([
      _result(
        main: 'Rumah Sakit Jih',
        detail: 'Jalan Kaliurang, Sleman',
        full: 'Jalan Kaliurang No.1, Gondangan, Sleman, DIY 55581, Indonesia',
      ),
    ]);

    await tester.pumpWidget(_app());
    await tester.pump();

    await tester.tap(find.text('Rumah Sakit Jih'));
    await tester.pumpAndSettle();

    // Pindah ke halaman home.
    expect(find.text('HALAMAN HOME'), findsOneWidget);

    // Data alamat benar-benar masuk ke penyimpanan.
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString(PrefsKeys.selectedAddress),
      'Jalan Kaliurang No.1, Gondangan, Sleman, DIY 55581, Indonesia',
    );
    expect(prefs.getBool(PrefsKeys.manualAddressSet), true);
    // Menandai supaya intro izin tampil di kunjungan berikutnya — berlaku
    // walau user masuk home lewat alamat manual (bukan izin lokasi).
    expect(prefs.getBool(PrefsKeys.hasReachedHome), true);
    expect(c.isSelecting.value, false);
  });
}
