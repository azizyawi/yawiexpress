import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wanmac/core/providers/location/location_providers.dart';
import 'package:wanmac/core/theme/app_colors.dart';
import 'package:wanmac/services/app_location_storage.dart';
import 'package:wanmac/views/screens/Authentication/LoginScreen/login_screen.dart';
import 'package:wanmac/views/screens/Authentication/create_account_screen.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _floatingController;
  late final AnimationController _buttonPressController;
  late final AnimationController _ridersWaveController;
  late final AnimationController _buttonShimmerController;

  late final Animation<double> _logoOpacity;
  late final Animation<Offset> _logoOffset;
  late final Animation<double> _headlineOpacity;
  late final Animation<Offset> _headlineOffset;
  late final Animation<double> _subtitleOpacity;
  late final Animation<Offset> _subtitleOffset;
  late final Animation<double> _imageOpacity;
  late final Animation<Offset> _imageEntranceOffset;
  late final Animation<double> _buttonOpacity;
  late final Animation<double> _buttonScale;
  late final Animation<double> _arrowShift;
  late final Animation<double> _buttonPressScale;

  bool _isRidersPressed = false;
  bool _locationAsked = false;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    _buttonPressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );

    _ridersWaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _buttonShimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.00, 0.18, curve: Curves.easeOut),
    );

    _logoOffset = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.00, 0.22, curve: Curves.easeOutCubic),
          ),
        );

    _headlineOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.12, 0.40, curve: Curves.easeOut),
    );

    _headlineOffset =
        Tween<Offset>(begin: const Offset(0, 0.16), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.12, 0.42, curve: Curves.easeOutCubic),
          ),
        );

    _subtitleOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.34, 0.54, curve: Curves.easeOut),
    );

    _subtitleOffset =
        Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.34, 0.56, curve: Curves.easeOutCubic),
          ),
        );

    _imageOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.42, 0.70, curve: Curves.easeOut),
    );

    _imageEntranceOffset =
        Tween<Offset>(begin: const Offset(0, 0.14), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.42, 0.74, curve: Curves.easeOutCubic),
          ),
        );

    _buttonOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.68, 0.90, curve: Curves.easeOut),
    );

    _buttonScale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.68, 0.92, curve: Curves.easeOutBack),
      ),
    );

    _arrowShift = Tween<double>(begin: 0, end: 4).animate(
      CurvedAnimation(parent: _buttonPressController, curve: Curves.easeOut),
    );

    _buttonPressScale = Tween<double>(begin: 1.0, end: 0.985).animate(
      CurvedAnimation(parent: _buttonPressController, curve: Curves.easeOut),
    );

    _entranceController.forward();

    Future.delayed(const Duration(milliseconds: 360), () {
      if (mounted) _ridersWaveController.forward();
    });

    _buttonShimmerController.repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _prepareLocation();
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) _floatingController.repeat(reverse: true);
    });
  }

  Future<void> _prepareLocation() async {
    if (_locationAsked) return;
    _locationAsked = true;

    try {
      final notifier = ref.read(locationNotifierProvider.notifier);
      await notifier.fetchCurrentLocation();

      final state = ref.read(locationNotifierProvider);
      final location = state.currentLocation;

      if (location != null) {
        notifier.setPickupLocation(location);
        await AppLocationStorage.savePickupLocation(location);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _floatingController.dispose();
    _buttonPressController.dispose();
    _ridersWaveController.dispose();
    _buttonShimmerController.dispose();
    super.dispose();
  }

  void _setRidersPressed(bool value) {
    if (_isRidersPressed != value) {
      setState(() => _isRidersPressed = value);
    }
  }

  void _onButtonTapDown(TapDownDetails details) {
    _buttonPressController.forward();
  }

  void _onButtonTapUp(TapUpDetails details) {
    _buttonPressController.reverse();
  }

  void _onButtonTapCancel() {
    _buttonPressController.reverse();
  }

  double _value({
    required double width,
    required double phone,
    required double tablet,
    required double desktop,
  }) {
    if (width >= 1000) return desktop;
    if (width >= 600) return tablet;
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final height = size.height;

    final isLandscape = width > height;
    final isShort = height < 700;
    final isTablet = width >= 600;

    final horizontalPadding = _value(
      width: width,
      phone: 28,
      tablet: 48,
      desktop: 64,
    );

    final maxContentWidth = isLandscape
        ? 900.0
        : _value(
            width: width,
            phone: double.infinity,
            tablet: 560,
            desktop: 620,
          );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            Widget content = Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: isLandscape ? 20 : 0,
                  ),
                  child: isLandscape
                      ? _LandscapeWelcomeLayout(
                          logoOpacity: _logoOpacity,
                          logoOffset: _logoOffset,
                          headlineOpacity: _headlineOpacity,
                          headlineOffset: _headlineOffset,
                          subtitleOpacity: _subtitleOpacity,
                          subtitleOffset: _subtitleOffset,
                          imageOpacity: _imageOpacity,
                          imageEntranceOffset: _imageEntranceOffset,
                          floatingController: _floatingController,
                          entranceController: _entranceController,
                          buttonOpacity: _buttonOpacity,
                          buttonScale: _buttonScale,
                          buttonPressScale: _buttonPressScale,
                          buttonPressController: _buttonPressController,
                          buttonShimmerController: _buttonShimmerController,
                          arrowShift: _arrowShift,
                          isRidersPressed: _isRidersPressed,
                          onPressChanged: _setRidersPressed,
                          ridersWaveController: _ridersWaveController,
                          onButtonTapDown: _onButtonTapDown,
                          onButtonTapUp: _onButtonTapUp,
                          onButtonTapCancel: _onButtonTapCancel,
                        )
                      : _PortraitWelcomeLayout(
                          logoOpacity: _logoOpacity,
                          logoOffset: _logoOffset,
                          headlineOpacity: _headlineOpacity,
                          headlineOffset: _headlineOffset,
                          subtitleOpacity: _subtitleOpacity,
                          subtitleOffset: _subtitleOffset,
                          imageOpacity: _imageOpacity,
                          imageEntranceOffset: _imageEntranceOffset,
                          floatingController: _floatingController,
                          entranceController: _entranceController,
                          buttonOpacity: _buttonOpacity,
                          buttonScale: _buttonScale,
                          buttonPressScale: _buttonPressScale,
                          buttonPressController: _buttonPressController,
                          buttonShimmerController: _buttonShimmerController,
                          arrowShift: _arrowShift,
                          isRidersPressed: _isRidersPressed,
                          onPressChanged: _setRidersPressed,
                          ridersWaveController: _ridersWaveController,
                          onButtonTapDown: _onButtonTapDown,
                          onButtonTapUp: _onButtonTapUp,
                          onButtonTapCancel: _onButtonTapCancel,
                          isTablet: isTablet,
                        ),
                ),
              ),
            );
            if (isLandscape || isShort) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: content,
                ),
              );
            }

            return SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: content,
            );
          },
        ),
      ),
    );
  }
}

class _PortraitWelcomeLayout extends StatelessWidget {
  final Animation<double> logoOpacity;
  final Animation<Offset> logoOffset;
  final Animation<double> headlineOpacity;
  final Animation<Offset> headlineOffset;
  final Animation<double> subtitleOpacity;
  final Animation<Offset> subtitleOffset;
  final Animation<double> imageOpacity;
  final Animation<Offset> imageEntranceOffset;
  final AnimationController floatingController;
  final AnimationController entranceController;
  final Animation<double> buttonOpacity;
  final Animation<double> buttonScale;
  final Animation<double> buttonPressScale;
  final AnimationController buttonPressController;
  final AnimationController buttonShimmerController;
  final Animation<double> arrowShift;
  final bool isRidersPressed;
  final ValueChanged<bool> onPressChanged;
  final AnimationController ridersWaveController;
  final GestureTapDownCallback onButtonTapDown;
  final GestureTapUpCallback onButtonTapUp;
  final GestureTapCancelCallback onButtonTapCancel;
  final bool isTablet;

  const _PortraitWelcomeLayout({
    required this.logoOpacity,
    required this.logoOffset,
    required this.headlineOpacity,
    required this.headlineOffset,
    required this.subtitleOpacity,
    required this.subtitleOffset,
    required this.imageOpacity,
    required this.imageEntranceOffset,
    required this.floatingController,
    required this.entranceController,
    required this.buttonOpacity,
    required this.buttonScale,
    required this.buttonPressScale,
    required this.buttonPressController,
    required this.buttonShimmerController,
    required this.arrowShift,
    required this.isRidersPressed,
    required this.onPressChanged,
    required this.ridersWaveController,
    required this.onButtonTapDown,
    required this.onButtonTapUp,
    required this.onButtonTapCancel,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final height = size.height;
    final width = size.width;
    final isShort = height < 720;

    final handWidth = isTablet
        ? width.clamp(330.0, 430.0)
        : (width * 0.78).clamp(260.0, 330.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AnimatedWelcomeHeading(
          logoOpacity: logoOpacity,
          logoOffset: logoOffset,
          headlineOpacity: headlineOpacity,
          headlineOffset: headlineOffset,
          subtitleOpacity: subtitleOpacity,
          subtitleOffset: subtitleOffset,
          isRidersPressed: isRidersPressed,
          onPressChanged: onPressChanged,
          ridersWaveController: ridersWaveController,
          shimmerController: buttonShimmerController,
          compact: isShort,
        ),

        Expanded(
          child: Center(
            child: _FloatingWelcomeImage(
              imageOpacity: imageOpacity,
              imageEntranceOffset: imageEntranceOffset,
              floatingController: floatingController,
              entranceController: entranceController,
              width: handWidth,
              xOffset: -8,
            ),
          ),
        ),

        _WelcomeActions(
          buttonOpacity: buttonOpacity,
          buttonScale: buttonScale,
          buttonPressScale: buttonPressScale,
          buttonPressController: buttonPressController,
          buttonShimmerController: buttonShimmerController,
          arrowShift: arrowShift,
          onButtonTapDown: onButtonTapDown,
          onButtonTapUp: onButtonTapUp,
          onButtonTapCancel: onButtonTapCancel,
          buttonHeight: isTablet ? 60 : 56,
          bottomSpacing: isShort ? 12 : 18,
        ),
      ],
    );
  }
}

class _LandscapeWelcomeLayout extends StatelessWidget {
  final Animation<double> logoOpacity;
  final Animation<Offset> logoOffset;
  final Animation<double> headlineOpacity;
  final Animation<Offset> headlineOffset;
  final Animation<double> subtitleOpacity;
  final Animation<Offset> subtitleOffset;
  final Animation<double> imageOpacity;
  final Animation<Offset> imageEntranceOffset;
  final AnimationController floatingController;
  final AnimationController entranceController;
  final Animation<double> buttonOpacity;
  final Animation<double> buttonScale;
  final Animation<double> buttonPressScale;
  final AnimationController buttonPressController;
  final AnimationController buttonShimmerController;
  final Animation<double> arrowShift;
  final bool isRidersPressed;
  final ValueChanged<bool> onPressChanged;
  final AnimationController ridersWaveController;
  final GestureTapDownCallback onButtonTapDown;
  final GestureTapUpCallback onButtonTapUp;
  final GestureTapCancelCallback onButtonTapCancel;

  const _LandscapeWelcomeLayout({
    required this.logoOpacity,
    required this.logoOffset,
    required this.headlineOpacity,
    required this.headlineOffset,
    required this.subtitleOpacity,
    required this.subtitleOffset,
    required this.imageOpacity,
    required this.imageEntranceOffset,
    required this.floatingController,
    required this.entranceController,
    required this.buttonOpacity,
    required this.buttonScale,
    required this.buttonPressScale,
    required this.buttonPressController,
    required this.buttonShimmerController,
    required this.arrowShift,
    required this.isRidersPressed,
    required this.onPressChanged,
    required this.ridersWaveController,
    required this.onButtonTapDown,
    required this.onButtonTapUp,
    required this.onButtonTapCancel,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final imageWidth = (size.width * 0.34).clamp(210.0, 340.0);

    return Row(
      children: [
        Expanded(
          flex: 11,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AnimatedWelcomeHeading(
                logoOpacity: logoOpacity,
                logoOffset: logoOffset,
                headlineOpacity: headlineOpacity,
                headlineOffset: headlineOffset,
                subtitleOpacity: subtitleOpacity,
                subtitleOffset: subtitleOffset,
                isRidersPressed: isRidersPressed,
                onPressChanged: onPressChanged,
                ridersWaveController: ridersWaveController,
                shimmerController: buttonShimmerController,
                compact: true,
                landscape: true,
              ),
              const SizedBox(height: 18),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: _WelcomeActions(
                  buttonOpacity: buttonOpacity,
                  buttonScale: buttonScale,
                  buttonPressScale: buttonPressScale,
                  buttonPressController: buttonPressController,
                  buttonShimmerController: buttonShimmerController,
                  arrowShift: arrowShift,
                  onButtonTapDown: onButtonTapDown,
                  onButtonTapUp: onButtonTapUp,
                  onButtonTapCancel: onButtonTapCancel,
                  buttonHeight: 50,
                  bottomSpacing: 0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 9,
          child: Center(
            child: _FloatingWelcomeImage(
              imageOpacity: imageOpacity,
              imageEntranceOffset: imageEntranceOffset,
              floatingController: floatingController,
              entranceController: entranceController,
              width: imageWidth,
              xOffset: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _AnimatedWelcomeHeading extends StatelessWidget {
  final Animation<double> logoOpacity;
  final Animation<Offset> logoOffset;
  final Animation<double> headlineOpacity;
  final Animation<Offset> headlineOffset;
  final Animation<double> subtitleOpacity;
  final Animation<Offset> subtitleOffset;
  final bool isRidersPressed;
  final ValueChanged<bool> onPressChanged;
  final AnimationController ridersWaveController;
  final AnimationController shimmerController;
  final bool compact;
  final bool landscape;

  const _AnimatedWelcomeHeading({
    required this.logoOpacity,
    required this.logoOffset,
    required this.headlineOpacity,
    required this.headlineOffset,
    required this.subtitleOpacity,
    required this.subtitleOffset,
    required this.isRidersPressed,
    required this.onPressChanged,
    required this.ridersWaveController,
    required this.shimmerController,
    this.compact = false,
    this.landscape = false,
  });

  double _value({
    required double width,
    required double phone,
    required double tablet,
    required double desktop,
  }) {
    if (width >= 1000) return desktop;
    if (width >= 600) return tablet;
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;

    final ridersColor = isRidersPressed
        ? AppColors.brandBlue
        : AppColors.brandBlueDark;

    final logoWidth = landscape
        ? 220.0
        : _value(width: width, phone: 300, tablet: 340, desktop: 360);

    final logoLeftShift = landscape
        ? -42.0
        : _value(width: width, phone: -52, tablet: -64, desktop: -72);

    final headingLift = landscape
        ? -30.0
        : compact
        ? -34.0
        : -46.0;

    final headlineSize = landscape
        ? 28.0
        : _value(
            width: width,
            phone: compact ? 28 : 31,
            tablet: 36,
            desktop: 38,
          );

    final subtitleSize = landscape
        ? 13.5
        : _value(width: width, phone: 14, tablet: 15, desktop: 16);

    final subtitleMaxWidth = landscape
        ? 360.0
        : _value(width: width, phone: 300, tablet: 430, desktop: 460);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeTransition(
          opacity: logoOpacity,
          child: SlideTransition(
            position: logoOffset,
            child: Transform.translate(
              offset: Offset(logoLeftShift, 0),
              child: Image.asset(
                'assets/images/wanpadi.png',
                width: logoWidth,
                fit: BoxFit.contain,
                alignment: Alignment.centerLeft,
              ),
            ),
          ),
        ),
        Transform.translate(
          offset: Offset(0, headingLift),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeTransition(
                opacity: headlineOpacity,
                child: SlideTransition(
                  position: headlineOffset,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Send packages',
                        style: GoogleFonts.montserrat(
                          fontSize: headlineSize,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTapDown: (_) => onPressChanged(true),
                        onTapUp: (_) => onPressChanged(false),
                        onTapCancel: () => onPressChanged(false),
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.end,
                          children: [
                            Text(
                              'with trusted ',
                              style: GoogleFonts.montserrat(
                                fontSize: headlineSize,
                                fontWeight: FontWeight.w500,
                                height: 1.15,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            _InfiniteWaveRiders(
                              waveController: shimmerController,
                              initialController: ridersWaveController,
                              color: ridersColor,
                              fontSize: headlineSize,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: compact ? 6 : 10),
              FadeTransition(
                opacity: subtitleOpacity,
                child: SlideTransition(
                  position: subtitleOffset,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: subtitleMaxWidth),
                    child: Text(
                      'Book a rider in minutes and deliver your package quickly and safely.',
                      style: GoogleFonts.montserrat(
                        fontSize: subtitleSize,
                        fontWeight: FontWeight.w400,
                        height: 1.55,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FloatingWelcomeImage extends StatelessWidget {
  final Animation<double> imageOpacity;
  final Animation<Offset> imageEntranceOffset;
  final AnimationController floatingController;
  final AnimationController entranceController;
  final double width;
  final double xOffset;

  const _FloatingWelcomeImage({
    required this.imageOpacity,
    required this.imageEntranceOffset,
    required this.floatingController,
    required this.entranceController,
    required this.width,
    required this.xOffset,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([entranceController, floatingController]),
      builder: (context, child) {
        final floatY = math.sin(floatingController.value * 2 * math.pi) * 6;

        return Opacity(
          opacity: imageOpacity.value,
          child: Transform.translate(
            offset: Offset(
              xOffset,
              (imageEntranceOffset.value.dy * 40) - floatY,
            ),
            child: child,
          ),
        );
      },
      child: SizedBox(
        width: width,
        child: Image.asset(
          'assets/images/welcome_hand.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _WelcomeActions extends StatelessWidget {
  final Animation<double> buttonOpacity;
  final Animation<double> buttonScale;
  final Animation<double> buttonPressScale;
  final AnimationController buttonPressController;
  final AnimationController buttonShimmerController;
  final Animation<double> arrowShift;
  final GestureTapDownCallback onButtonTapDown;
  final GestureTapUpCallback onButtonTapUp;
  final GestureTapCancelCallback onButtonTapCancel;
  final double buttonHeight;
  final double bottomSpacing;

  const _WelcomeActions({
    required this.buttonOpacity,
    required this.buttonScale,
    required this.buttonPressScale,
    required this.buttonPressController,
    required this.buttonShimmerController,
    required this.arrowShift,
    required this.onButtonTapDown,
    required this.onButtonTapUp,
    required this.onButtonTapCancel,
    required this.buttonHeight,
    required this.bottomSpacing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FadeTransition(
          opacity: buttonOpacity,
          child: AnimatedBuilder(
            animation: Listenable.merge([buttonScale, buttonPressController]),
            builder: (context, child) {
              return Transform.scale(
                scale: buttonScale.value * buttonPressScale.value,
                child: child,
              );
            },
            child: GestureDetector(
              onTapDown: onButtonTapDown,
              onTapUp: onButtonTapUp,
              onTapCancel: onButtonTapCancel,
              child: AnimatedBuilder(
                animation: buttonShimmerController,
                builder: (context, child) {
                  final shimmer = 1 + (buttonShimmerController.value * 0.02);
                  return Transform.scale(scale: shimmer, child: child);
                },
                child: SizedBox(
                  width: double.infinity,
                  height: buttonHeight,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateAccountScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.brandBlueDark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Get Started',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            height: 24 / 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        AnimatedBuilder(
                          animation: buttonPressController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(arrowShift.value, 0),
                              child: child,
                            );
                          },
                          child: const Icon(
                            Icons.arrow_forward,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => LoginScreen()),
            );
          },
          child: FadeTransition(
            opacity: buttonOpacity,
            child: Center(
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Already have an account? ',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    TextSpan(
                      text: 'Log in',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandBlueDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: bottomSpacing),
      ],
    );
  }
}

class _InfiniteWaveRiders extends StatelessWidget {
  final AnimationController waveController;
  final AnimationController initialController;
  final Color color;
  final double fontSize;

  static const String _word = 'riders';

  const _InfiniteWaveRiders({
    required this.waveController,
    required this.initialController,
    required this.color,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([waveController, initialController]),
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(_word.length, (index) {
            final start = index * 0.11;
            final end = (start + 0.4).clamp(0.0, 1.0);

            final curved = CurvedAnimation(
              parent: initialController,
              curve: Interval(start, end, curve: Curves.easeOutBack),
            );

            final rise = Tween<double>(begin: 4, end: 0).evaluate(curved);

            final opacity = Tween<double>(begin: 0, end: 1).evaluate(
              CurvedAnimation(
                parent: initialController,
                curve: Interval(start, end, curve: Curves.easeOut),
              ),
            );

            final floatY =
                math.sin((waveController.value * 2 * math.pi) + index * 0.2) *
                2;

            return Opacity(
              opacity: opacity,
              child: Transform.translate(
                offset: Offset(0, rise + floatY),
                child: Text(
                  _word[index],
                  style: GoogleFonts.montserrat(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    color: color,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
