import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/controllers/splash_controller.dart';
import '../app/theme/app_colors.dart';
import '../widgets/gradient_button.dart';

class SplashPage extends GetView<SplashController> {
  const SplashPage({super.key});

  static const String _logoAsset = 'assets/images/sehatlylogo.png';
  static const String _textAsset = 'assets/images/text.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.dark, AppColors.midBlue, AppColors.lightBlue],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: _SplashContent(onCta: controller.goHome),
          ),
        ),
      ),
    );
  }
}

class _SplashContent extends StatefulWidget {
  const _SplashContent({required this.onCta});
  final VoidCallback onCta;

  @override
  State<_SplashContent> createState() => _SplashContentState();
}

class _SplashContentState extends State<_SplashContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  late final Animation<double> _brandFade;
  late final Animation<Offset> _brandSlide;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _bottomFade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _brandFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOutCubic),
    );
    _brandSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _ctrl,
            curve: const Interval(0.0, 0.35, curve: Curves.easeOutCubic),
          ),
        );
    _logoFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.25, 0.6, curve: Curves.easeOutCubic),
    );
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.25, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    _bottomFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.55, 1.0, curve: Curves.easeOutCubic),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(flex: 2),
        FadeTransition(
          opacity: _brandFade,
          child: SlideTransition(
            position: _brandSlide,
            child: Image.asset(
              SplashPage._textAsset,
              height: 44,
              fit: BoxFit.fitHeight,
            ),
          ),
        ),
        const SizedBox(height: 20),
        FadeTransition(
          opacity: _logoFade,
          child: ScaleTransition(
            scale: _logoScale,
            child: Image.asset(SplashPage._logoAsset, width: 250),
          ),
        ),
        const SizedBox(height: 44),
        FadeTransition(
          opacity: _bottomFade,
          child: Text(
            'Ada Keluhan Kesehatan?',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 26,
              height: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 8),
        FadeTransition(
          opacity: _bottomFade,
          child: Text(
            'Konsultasi dengan dokter kapan saja\ndan di mana saja',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 16,
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(height: 36),
        FadeTransition(
          opacity: _bottomFade,
          child: GradientButton(
            label: 'MULAI KONSULTASI',
            onPressed: widget.onCta,
          ),
        ),
        const Spacer(flex: 2),
      ],
    );
  }
}
