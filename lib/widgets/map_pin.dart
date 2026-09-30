import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Warna pin tengah peta — `assets/svg/pin.svg` di-recolor lewat
/// `colorFilter`, jadi file SVG-nya sendiri tidak perlu diubah.
const kMapPinColor = Color(0xFFE2195E);

/// Ukuran pin. Kotaknya dibuat dua kali tinggi pin: setengah atas berisi
/// pin, ujung pin tepat di tengah kotak = titik kamera peta.
const double kMapPinSize = 35;

/// Pin tengah layar peta, digambar oleh aplikasi (bukan marker Google)
/// supaya diam total di layar.
///
/// Lapisan (bawah → atas):
///   1) bayangan — bentuknya persis siluet icon SVG (bukan oval/tanah),
///      di-blur lalu digeser sedikit supaya terbaca sebagai bayangan
///      jatuh dari icon-nya sendiri
///   2) pin asli (crimson)
class MapPin extends StatelessWidget {
  const MapPin({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: kMapPinSize,
      height: kMapPinSize * 2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1) Bayangan siluet icon SVG (blur + geser halus)
          Positioned(
            left: 0,
            top: 0,
            child: Transform.translate(
              offset: const Offset(1.5, 2.5),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 3.2, sigmaY: 3.2),
                child: SvgPicture.asset(
                  'assets/svg/pin.svg',
                  width: kMapPinSize,
                  height: kMapPinSize,
                  fit: BoxFit.contain,
                  colorFilter: const ColorFilter.mode(
                    Color(0x59000000),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),

          // 2) Pin asli (crimson)
          Positioned(
            left: 0,
            top: 0,
            child: SvgPicture.asset(
              'assets/svg/pin.svg',
              width: kMapPinSize,
              height: kMapPinSize,
              fit: BoxFit.contain,
              colorFilter: const ColorFilter.mode(
                kMapPinColor,
                BlendMode.srcIn,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
