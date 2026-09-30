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
}
