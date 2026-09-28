import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app/models/permission_item.dart';
import '../app/theme/app_colors.dart';
class BoldText extends StatelessWidget {
  const BoldText(this.text, {super.key});
  final String text;

  List<TextSpan> _parse() {
    final parts = text.split('**');
    return [
      for (int i = 0; i < parts.length; i++)
        if (parts[i].isNotEmpty)
          TextSpan(
            text: parts[i],
            style: TextStyle(
              fontWeight: i.isOdd ? FontWeight.w600 : FontWeight.w400,
              color: i.isOdd ? const Color(0xFF374151) : const Color(0xFF6B7280),
            ),
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.poppins(fontSize: 12.5, height: 1.55),
        children: _parse(),
      ),
    );
  }
}

class PermissionTile extends StatelessWidget {
  const PermissionTile({super.key, required this.item});
  final PermissionItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(item.icon, size: 22, color: const Color(0xFF6B7280)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              BoldText(item.description),
            ],
          ),
        ),
      ],
    );
  }
}

class PrivacyFooter extends StatelessWidget {
  const PrivacyFooter({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.poppins(
          fontSize: 13,
          height: 1.6,
          color: const Color(0xFF6B7280),
        ),
        children: [
          const TextSpan(
            text: 'Kerahasiaan datamu adalah hal terpenting bagi kami. '
                'Sehatly memastikan datamu dikumpulkan dan digunakan sesuai dengan ',
          ),
          TextSpan(
            text: 'Kebijakan Privasi Sehatly.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.primary,
            ),
            recognizer: TapGestureRecognizer()..onTap = onTap,
          ),
        ],
      ),
    );
  }
}
