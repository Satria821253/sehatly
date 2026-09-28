import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:sehatly/app/theme/app_colors.dart';
import '../app/controllers/splash_controller.dart';

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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _ctrl;

  late final Animation<double> _brandFade;
  late final Animation<Offset> _brandSlide;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _textFade;
  late final Animation<double> _buttonFade;
  late final Animation<Offset> _buttonSlide;
  String _version = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = info.version);
    });
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _brandFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.25, curve: Curves.easeOutCubic),
    );
    _brandSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.25, curve: Curves.easeOutCubic),
    ));
    _logoFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.15, 0.4, curve: Curves.easeOutCubic),
    );
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.15, 0.4, curve: Curves.easeOutCubic),
    ));
    _textFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.4, 0.65, curve: Curves.easeOutCubic),
    );
    _buttonFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.72, 1.0, curve: Curves.easeOutCubic),
    );
    _buttonSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.72, 1.0, curve: Curves.easeOutCubic),
    ));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        !_ctrl.isAnimating &&
        _ctrl.value == 0) {
      _ctrl.forward();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted && _ctrl.value == 0) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
            child: Image.asset(SplashPage._textAsset, height: 44, fit: BoxFit.fitHeight),
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
          opacity: _textFade,
          child: Text(
            'ADA KELUHAN\nKESIHATAN?\nKONSULTASI SEKARANG.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 22,
              height: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 24),
        FadeTransition(
          opacity: _buttonFade,
          child: SlideTransition(
            position: _buttonSlide,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onCta,
                  borderRadius: BorderRadius.circular(40),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.dark.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Text(
                        'SEHAT LEBIH MUDAH!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const Spacer(flex: 2),
        if (_version.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'v$_version'.toUpperCase(),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
          ),
      ],
    );
  }
}
