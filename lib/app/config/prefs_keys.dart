/// Kunci SharedPreferences dipusatkan di sini supaya tidak ada literal
/// yang terpencar di beberapa file dan salah eja saat ada yang diubah.
class PrefsKeys {
  PrefsKeys._();

  /// Alamat lengkap yang dipilih user (pencarian / peta / GPS).
  static const String selectedAddress = 'selected_address';

  /// Koordinat titik yang dipilih user.
  static const String selectedLat = 'selected_lat';
  static const String selectedLng = 'selected_lng';

  /// true = user pernah memilih alamat manual → splash boleh langsung
  /// ke home tanpa lewat halaman izin lokasi.
  static const String manualAddressSet = 'manual_address_set';

  /// true = user pernah sampai halaman home.
  static const String hasReachedHome = 'has_reached_home';

  /// true = user sudah melihat halaman "Penggunaan Data & Izin".
  static const String hasSeenIntro = 'has_seen_intro';

  /// true = user sudah menyetujui pemakaian izin di halaman intro.
  static const String permissionConsentGiven = 'permission_consent_given';
}
