import 'package:flutter/material.dart';

import '../app/theme/app_colors.dart';

const _shadow = [
  BoxShadow(color: Color(0x38000000), blurRadius: 8, offset: Offset(0, 2)),
];

/// Tombol bundar melayang di atas peta (tombol "lokasi saya", tombol kembali).
class RoundMapButton extends StatelessWidget {
  const RoundMapButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.busy = false,
  });

  final IconData icon;
  final VoidCallback onTap;

  /// true → tampilkan spinner (lagi mengambil lokasi GPS).
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: _shadow,
        ),
        child: busy
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: AppColors.primary,
                ),
              )
            : Icon(icon, size: 21, color: const Color(0xFF1D2733)),
      ),
    );
  }
}
