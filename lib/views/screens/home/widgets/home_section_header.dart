import 'package:flutter/material.dart';
import 'package:wanmac/core/theme/app_colors.dart';
import 'package:wanmac/views/screens/home/widgets/home_helmet_illustration.dart';
import 'package:wanmac/views/screens/home/widgets/home_hero_background_painter.dart';
import 'package:wanmac/views/screens/home/widgets/home_services_overlay.dart';
import 'package:wanmac/views/screens/home/widgets/home_text_style.dart';
import 'package:wanmac/views/screens/home/widgets/home_top_bar.dart';

class HomeHeroSection extends StatefulWidget {
  final Animation<double> heroFade;
  final Animation<Offset> heroSlide;
  final AnimationController ctaPressController;
  final Animation<double> ctaPressScale;
  final VoidCallback onSendPackage;
  final Function(String feature) onComingSoon;

  const HomeHeroSection({
    super.key,
    required this.heroFade,
    required this.heroSlide,
    required this.ctaPressController,
    required this.ctaPressScale,
    required this.onSendPackage,
    required this.onComingSoon,
  });

  @override
  State<HomeHeroSection> createState() => _HomeHeroSectionState();
}

class _HomeHeroSectionState extends State<HomeHeroSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pathController;

  @override
  void initState() {
    super.initState();

    _pathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  bool _isTablet(BuildContext context) {
    return MediaQuery.sizeOf(context).shortestSide >= 600;
  }

  bool _isLandscape(BuildContext context) {
    return MediaQuery.orientationOf(context) == Orientation.landscape;
  }

  bool _isShortHeight(BuildContext context) {
    return MediaQuery.sizeOf(context).height < 700;
  }

  double _heroMaxWidth(BuildContext context) {
    final isTablet = _isTablet(context);
    final isLandscape = _isLandscape(context);

    if (isTablet && isLandscape) return 1120;
    if (isTablet) return 680;
    if (isLandscape) return 920;
    return double.infinity;
  }

  double _heroHeight(BuildContext context) {
    final isTablet = _isTablet(context);
    final isLandscape = _isLandscape(context);
    final isShort = _isShortHeight(context);

    if (isTablet && isLandscape) return 220;
    if (isTablet) return 210;
    if (isLandscape) return 150;
    if (isShort) return 150;
    return 168;
  }

  EdgeInsets _horizontalPadding(BuildContext context) {
    final isTablet = _isTablet(context);

    return EdgeInsets.symmetric(horizontal: isTablet ? 32 : 20);
  }

  double _titleSize(BuildContext context) {
    final isTablet = _isTablet(context);
    final isLandscape = _isLandscape(context);
    final isShort = _isShortHeight(context);

    if (isTablet) return 32;
    if (isLandscape || isShort) return 22;
    return 24;
  }

  double _titleWidth(BuildContext context) {
    final isTablet = _isTablet(context);
    final isLandscape = _isLandscape(context);

    if (isTablet && isLandscape) return 320;
    if (isTablet) return 300;
    if (isLandscape) return 260;
    return 190;
  }

  double _overlayOffset(BuildContext context) {
    final isLandscape = _isLandscape(context);
    final isShort = _isShortHeight(context);

    if (isLandscape || isShort) return -10;
    return -14;
  }

  Widget _buildCta(BuildContext context) {
    final isTablet = _isTablet(context);
    final isLandscape = _isLandscape(context);
    final isShort = _isShortHeight(context);

    return AnimatedBuilder(
      animation: widget.ctaPressController,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.ctaPressScale.value,
          alignment: Alignment.centerLeft,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: (_) => widget.ctaPressController.forward(),
        onTapCancel: () => widget.ctaPressController.reverse(),
        onTapUp: (_) => widget.ctaPressController.reverse(),
        onTap: widget.onSendPackage,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 18 : 16,
            vertical: isLandscape || isShort ? 9 : 10,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: isTablet ? 32 : 28,
                height: isTablet ? 32 : 28,
                decoration: BoxDecoration(
                  color: AppColors.brandBlueDark.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.two_wheeler_rounded,
                  color: AppColors.brandBlueDark,
                  size: isTablet ? 19 : 17,
                ),
              ),
              const SizedBox(width: 9),
              Text(
                'Send a Package',
                style: sf(
                  size: isTablet ? 15 : 14,
                  weight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    final heroHeight = _heroHeight(context);
    final isTablet = _isTablet(context);
    final isLandscape = _isLandscape(context);
    final isShort = _isShortHeight(context);

    return SizedBox(
      height: heroHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(0),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pathController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: HomeHeroBackgroundPainter(_pathController.value),
                  );
                },
              ),
            ),

            Positioned(
              right: isTablet ? 120 : 82,
              top: isLandscape || isShort ? 18 : 24,
              child: Icon(
                Icons.inventory_2_outlined,
                color: Colors.white.withOpacity(.14),
                size: isTablet ? 42 : 32,
              ),
            ),

            Positioned(
              right: isTablet ? 220 : 150,
              bottom: isLandscape || isShort ? 28 : 34,
              child: Icon(
                Icons.route_rounded,
                color: Colors.white.withOpacity(.10),
                size: isTablet ? 54 : 42,
              ),
            ),

            Positioned(
              left: isTablet ? 280 : 225,
              top: isLandscape || isShort ? 28 : 36,
              child: Icon(
                Icons.add_rounded,
                color: Colors.white.withOpacity(.18),
                size: isTablet ? 24 : 20,
              ),
            ),

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: isTablet ? 5 : 6,
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: isTablet ? 18 : 8,
                      top: isLandscape || isShort ? 4 : 0,
                    ),
                    child: Column(
                      mainAxisAlignment: isLandscape || isShort
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: _titleWidth(context),
                          child: Text(
                            'Deliver with confidence',
                            style: sf(
                              size: _titleSize(context),
                              weight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.06,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        SizedBox(height: isLandscape || isShort ? 10 : 14),
                        _buildCta(context),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: isTablet ? 5 : 4,
                  child: const Align(
                    alignment: Alignment.centerRight,
                    child: HomeHelmetIllustration(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenteredHero(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: _heroMaxWidth(context)),
        child: Padding(
          padding: _horizontalPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HomeTopBar(),
              const SizedBox(height: 8),
              _buildHeroCard(context),
              Transform.translate(
                offset: Offset(0, _overlayOffset(context)),
                child: HomeServicesOverlay(
                  onBillsTap: () => widget.onComingSoon('Bills'),
                  onFoodTap: () => widget.onComingSoon('Food'),
                  onSendTap: widget.onSendPackage,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = _isLandscape(context);
    final isShort = _isShortHeight(context);

    return FadeTransition(
      opacity: widget.heroFade,
      child: SlideTransition(
        position: widget.heroSlide,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.only(bottom: isLandscape || isShort ? 4 : 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.brandBlueDark, AppColors.brandBlueDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.only(top: isLandscape || isShort ? 6 : 8),
              child: _buildCenteredHero(context),
            ),
          ),
        ),
      ),
    );
  }
}
