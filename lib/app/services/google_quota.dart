import 'package:shared_preferences/shared_preferences.dart';

/// Pembatas pemakaian API Google **per hari** — dipasang karena aplikasi ini
/// masih tahap develop, supaya kuota gratis Google (10.000 request/bulan)
/// tidak terbakar habis oleh percobaan/degbug berulang.
///
/// Cara kerja:
///  - request Google hanya dijalankan bila [isAllowed] == true
///  - hanya request yang **berhasil** yang dihitung (gagal/blocked tidak)
///  - pencarian otomatis jatuh ke OpenStreetMap bila kuota habis
///  - pencacahan disimpan di SharedPreferences dan di-reset otomatis
///    setiap pergantian hari
class GoogleQuota {
  GoogleQuota._();

  /// Batas request Google sukses per hari. Ubah angka ini sesuai kebutuhan.
  /// (Google gratis 10.000/bulan ≈ 333/hari — 200 masih aman di bawahnya.)
  static const int maxPerDay = 200;

  static const String _countKey = 'google_api_used_count';
  static const String _dateKey = 'google_api_used_date';

  static int _used = 0;
  static String _date = _today();
  static bool _ready = false;

  static String _today() {
    final now = DateTime.now();
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    return '${now.year}-$mm-$dd';
  }

  static Future<void> _ensureLoaded() async {
    if (_ready) return;
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(_dateKey);
    _date = _today();
    _used = savedDate == _date ? (prefs.getInt(_countKey) ?? 0) : 0;
    _ready = true;
  }

  static Future<void> _rolloverIfNeeded() async {
    final today = _today();
    if (today == _date) return;
    _date = today;
    _used = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dateKey, today);
    await prefs.setInt(_countKey, 0);
  }

  /// Jumlah pemakaian Google hari ini (untuk log/debug).
  static int get used => _used;

  /// Sisa kuota hari ini.
  static int get remaining =>
      _used >= maxPerDay ? 0 : maxPerDay - _used;

  /// Bolehkah memanggil API Google sekarang?
  static Future<bool> isAllowed() async {
    await _ensureLoaded();
    await _rolloverIfNeeded();
    if (_used >= maxPerDay) {
      return false;
    }
    return true;
  }

  /// Catat 1 request Google yang **berhasil**.
  static Future<void> recordSuccess() async {
    await _ensureLoaded();
    await _rolloverIfNeeded();
    _used++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dateKey, _date);
    await prefs.setInt(_countKey, _used);
  }
}
