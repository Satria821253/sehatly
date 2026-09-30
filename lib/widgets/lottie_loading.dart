import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Animasi loading bawaan aplikasi (assets/lottie/loading.json,
/// 300×300, 30 fps, satu putaran ±1,4 detik — diputar terus-menerus).
class LottieLoading extends StatelessWidget {
  const LottieLoading({super.key, this.size = 220});

  /// Lebar/tinggi animasi dalam logical pixel.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/lottie/loading.json',
      width: size,
      height: size,
      fit: BoxFit.contain,
      repeat: true,
    );
  }
}
