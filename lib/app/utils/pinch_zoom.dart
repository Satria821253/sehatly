import 'dart:math' as math;
import 'dart:ui' show Offset;

/// Zoom dua jari yang **berpusat di tengah layar** untuk halaman peta.
///
/// Zoom bawaan Google Maps berpusat di titik jari, sehingga lokasi di
/// bawah pin ikut bergeser setiap kali pinch (pin terlihat "melar").
/// Di sini jari hanya dipakai untuk menghitung *seberapa banyak* zoom,
/// lalu kameranya digerakkan dengan `CameraUpdate.zoomTo` — target
/// kamera (titik di bawah pin) tetap.
///
/// Pemakaian dari halaman:
/// ```dart
/// if (_pinch.pointerDown(e.pointer, e.position)) setState(() {});
/// final z = _pinch.pointerMove(e.pointer, e.position);
/// if (z != null) _map?.moveCamera(CameraUpdate.zoomTo(z));
/// if (_pinch.pointerUp(e.pointer)) setState(() {});
/// ```
class PinchZoomController {
  final Map<int, Offset> _pointers = {};
  double? _startDist;
  double _startZoom = 16;

  /// Zoom kamera terakhir — diperbarui halaman dari `onCameraMove`
  /// supaya gesture berikutnya dihitung dari zoom yang benar-benar aktif.
  double zoom = 16;

  /// true saat dua jari menyentuh layar → mode zoom (geser dimatikan
  /// lewat `scrollGesturesEnabled`).
  bool multiTouch = false;

  /// Catat jari yang menyentuh layar.
  ///
  /// Mengembalikan true bila status [multiTouch] berubah — halaman wajib
  /// membangun ulang UI (setState) pada nilai true.
  bool pointerDown(int pointer, Offset position) {
    _pointers[pointer] = position;
    if (_pointers.length == 2) {
      _startDist = _distance();
      _startZoom = zoom;
      multiTouch = true;
      return true;
    }
    return false;
  }

  /// Hitung zoom target untuk kamera, atau null kalau ini bukan gesture
  /// zoom (jarinya kurang dari dua).
  double? pointerMove(int pointer, Offset position) {
    if (!_pointers.containsKey(pointer)) return null;
    _pointers[pointer] = position;
    if (_pointers.length == 2 && _startDist != null && _startDist! > 0) {
      // Kelipatan dua jari = satu tingkat zoom → log basis 2.
      // Dibatasi 3..21 (rentang aman zoom Google Maps).
      return (_startZoom + math.log(_distance() / _startDist!) / math.ln2)
          .clamp(3.0, 21.0);
    }
    return null;
  }

  /// Catat jari yang diangkat.
  ///
  /// Mengembalikan true bila mode zoom baru saja berakhir (halaman wajib
  /// membangun ulang UI pada nilai true).
  bool pointerUp(int pointer) {
    _pointers.remove(pointer);
    if (_pointers.length < 2) {
      _startDist = null;
      if (multiTouch) {
        multiTouch = false;
        return true;
      }
    }
    return false;
  }

  /// Jarak antara dua jari yang sedang menyentuh layar.
  double _distance() {
    final p = _pointers.values.toList();
    return (p[0] - p[1]).distance;
  }
}
