// Alur onboarding: splash -> intro perizinan -> izin lokasi -> pilih alamat.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sehatly/main.dart';

const MethodChannel _geolocatorChannel =
    MethodChannel('flutter.baseflow.com/geolocator');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
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
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_geolocatorChannel, null);
  });

  testWidgets('Splash -> intro perizinan -> izin lokasi -> pilih alamat',
      (tester) async {
    await tester.pumpWidget(const MyApp());
    // Biarkan animasi splash selesai.
    await tester.pump(const Duration(milliseconds: 2100));
    expect(find.text('MULAI KONSULTASI'), findsOneWidget);

    // Dari splash ke halaman intro perizinan (belum menyetujui).
    await tester.tap(find.text('MULAI KONSULTASI'));
    await tester.pumpAndSettle();
    expect(find.text('SAYA SETUJUI'), findsOneWidget);
    expect(find.text('LOKASI'), findsOneWidget);

    // Setuju -> lanjut ke halaman izin lokasi.
    await tester.tap(find.text('SAYA SETUJUI'));
    await tester.pumpAndSettle();
    expect(find.text('TENTUKAN ALAMAT'), findsOneWidget);

    // Buka sheet pemilihan alamat.
    await tester.tap(find.text('TENTUKAN ALAMAT'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih Alamat'), findsOneWidget);

    // Siram timer auto-navigate splash yang masih tertunda.
    await tester.pump(const Duration(seconds: 4));
  });
}
