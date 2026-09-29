import 'api_key.g.dart';

/// Konfigurasi API Google untuk pencarian & alamat.
///
/// API key-nya sendiri ada di `api_key.g.dart` yang **masuk daftar .gitignore**
/// supaya tidak ikut ter-push ke repository. Kalau file itu hilang (fresh
/// clone), salin `api_key.g.example.dart` menjadi `api_key.g.dart`.
class GoogleApi {
  GoogleApi._();

  static const String apiKey = googleApiKey;

  /// Bahasa hasil: Indonesia.
  static const String language = 'id';

  /// Batasi hasil ke Indonesia supaya search tidak nyasar ke luar negeri.
  static const String countryCode = 'id';
}
