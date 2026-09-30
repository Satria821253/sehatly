import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sehatly/widgets/error_message.dart';

void main() {
  /// Layar berisi tombol pemicu yang memanggil [showErrorSnack].
  Widget host(void Function()? onAction) => MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showErrorSnack(
                  context,
                  'Lokasi perangkat (GPS) sedang dimatikan.',
                  icon: Icons.gps_off_rounded,
                  actionLabel: 'NYALAKAN',
                  onAction: onAction,
                ),
                child: const Text('pemicu'),
              ),
            ),
          ),
        ),
      );

  testWidgets('kartu pesan tampil lengkap: ikon, teks, dan tombol aksi',
      (tester) async {
    await tester.pumpWidget(host(null));
    await tester.tap(find.text('pemicu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Lokasi perangkat (GPS) sedang dimatikan.'),
        findsOneWidget);
    expect(find.text('NYALAKAN'), findsOneWidget);
    expect(find.byIcon(Icons.gps_off_rounded), findsOneWidget);
  });

  testWidgets('tombol aksi dipanggil dan kartu langsung ditutup',
      (tester) async {
    var aksiDijalankan = false;
    await tester.pumpWidget(host(() => aksiDijalankan = true));

    await tester.tap(find.text('pemicu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('NYALAKAN'));
    await tester.pumpAndSettle();

    expect(aksiDijalankan, isTrue);
    expect(find.text('NYALAKAN'), findsNothing);
    expect(find.text('Lokasi perangkat (GPS) sedang dimatikan.'), findsNothing);
  });

  testWidgets('pesan baru menggantikan pesan yang sedang tampil',
      (tester) async {
    await tester.pumpWidget(host(null));

    await tester.tap(find.text('pemicu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('pemicu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Tidak menumpuk: cukup satu kartu di layar.
    expect(find.text('NYALAKAN'), findsOneWidget);
  });

  /// Layar berisi tombol pemicu untuk fungsi pesan apa pun.
  Widget hostFor(void Function(BuildContext) show) => MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => show(context),
                child: const Text('pemicu'),
              ),
            ),
          ),
        ),
      );

  testWidgets('kartu "tidak ada internet" tampil dengan ikon wifi',
      (tester) async {
    await tester.pumpWidget(hostFor(showNoInternetSnack));
    await tester.tap(find.text('pemicu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('Tidak ada koneksi internet'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
  });

  testWidgets('kartu "gagal simpan alamat" tampil dengan ikon simpan',
      (tester) async {
    await tester.pumpWidget(hostFor(showAddressSaveFailedSnack));
    await tester.tap(find.text('pemicu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('Gagal menyimpan alamat'), findsOneWidget);
    expect(find.byIcon(Icons.save_alt_rounded), findsOneWidget);
  });

  testWidgets('kartu "gagal muat alamat" tampil dengan ikon peringatan',
      (tester) async {
    await tester.pumpWidget(hostFor(showAddressLoadFailedSnack));
    await tester.tap(find.text('pemicu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('Gagal memuat alamat'), findsOneWidget);
    expect(find.byIcon(Icons.sync_problem_rounded), findsOneWidget);
  });
}
