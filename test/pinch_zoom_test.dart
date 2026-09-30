import 'package:flutter_test/flutter_test.dart';
import 'package:sehatly/app/utils/pinch_zoom.dart';

void main() {
  group('PinchZoomController', () {
    test('satu jari tidak memicu mode zoom', () {
      final pinch = PinchZoomController();

      expect(pinch.pointerDown(1, const Offset(100, 100)), isFalse);
      expect(pinch.multiTouch, isFalse);
      expect(pinch.pointerMove(1, const Offset(150, 100)), isNull);
      expect(pinch.pointerUp(1), isFalse);
    });

    test('dua jari mengaktifkan mode zoom', () {
      final pinch = PinchZoomController();

      pinch.pointerDown(1, const Offset(100, 100));
      expect(pinch.pointerDown(2, const Offset(200, 100)), isTrue);
      expect(pinch.multiTouch, isTrue);
    });

    test('jari menjauh → zoom naik, jari mendekat → zoom turun', () {
      final pinch = PinchZoomController()..zoom = 16;

      pinch.pointerDown(1, const Offset(100, 100));
      pinch.pointerDown(2, const Offset(200, 100)); // jarak acuan = 100

      // Dua kali lipat jarak = +1 tingkat zoom.
      expect(pinch.pointerMove(2, const Offset(300, 100)), closeTo(17, 0.001));
      // Setengah jarak = -1 tingkat zoom.
      expect(pinch.pointerMove(2, const Offset(150, 100)), closeTo(15, 0.001));
    });

    test('zoom dibatasi rentang 3..21', () {
      final pinch = PinchZoomController()..zoom = 16;

      pinch.pointerDown(1, const Offset(100, 100));
      pinch.pointerDown(2, const Offset(101, 100)); // jarak acuan = 1

      expect(pinch.pointerMove(2, const Offset(10000, 100)), 21.0);
      expect(pinch.pointerMove(2, const Offset(100.0001, 100)), 3.0);
    });

    test('jari diangkat → keluar dari mode zoom', () {
      final pinch = PinchZoomController();

      pinch.pointerDown(1, const Offset(100, 100));
      pinch.pointerDown(2, const Offset(200, 100));
      expect(pinch.pointerUp(2), isTrue);
      expect(pinch.multiTouch, isFalse);

      // Sisa satu jari → tidak ada zoom lagi.
      expect(pinch.pointerMove(1, const Offset(300, 100)), isNull);
    });
  });
}
