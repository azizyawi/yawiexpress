import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wanmac/core/theme/app_colors.dart';

double _scale(BuildContext context) {
  final size = MediaQuery.sizeOf(context);

  final isTablet = size.shortestSide >= 600;
  final isShort = size.height < 700;

  if (isTablet) return 1.10;
  if (isShort) return 0.92;

  return 1.0;
}

double _maxContentWidth(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  final isTablet = size.shortestSide >= 600;

  if (isTablet) return 680;

  return double.infinity;
}

class PremiumPaymentLoader extends StatefulWidget {
  final String title;
  final String subtitle;

  const PremiumPaymentLoader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  State<PremiumPaymentLoader> createState() => _PremiumPaymentLoaderState();
}

class _PremiumPaymentLoaderState extends State<PremiumPaymentLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Material(
      color: Colors.transparent,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Align(
          alignment: Alignment.center,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: r(26)),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: _maxContentWidth(context) == double.infinity
                    ? r(360)
                    : 360,
              ),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(r(22), r(24), r(22), r(22)),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.94),
                  borderRadius: BorderRadius.circular(r(28)),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.22),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: r(40),
                      offset: Offset(0, r(18)),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: r(78),
                      height: r(78),
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (_, __) {
                          final turn = _controller.value;

                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              Transform.rotate(
                                angle: turn * 6.283185307179586,
                                child: Container(
                                  width: r(78),
                                  height: r(78),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.brandBlueDark
                                          .withOpacity(0.16),
                                      width: 1.4,
                                    ),
                                  ),
                                ),
                              ),
                              Transform.scale(
                                scale: 0.78,
                                child: Container(
                                  width: r(78),
                                  height: r(78),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.brandBlueDark
                                          .withOpacity(0.24),
                                      width: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: r(34),
                                height: r(34),
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.brandBlue,
                                  ),
                                ),
                              ),
                              Container(
                                width: r(10),
                                height: r(10),
                                decoration: const BoxDecoration(
                                  color: AppColors.brandBlue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    SizedBox(height: r(22)),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: r(16),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.25,
                        height: 1.25,
                      ),
                    ),
                    SizedBox(height: r(8)),
                    Text(
                      widget.subtitle,
                      textAlign: TextAlign.center,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: r(12.5),
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                    SizedBox(height: r(18)),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: r(12),
                        vertical: r(10),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.infoBg,
                        borderRadius: BorderRadius.circular(r(16)),
                        border: Border.all(color: AppColors.infoBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: r(15),
                            color: AppColors.brandBlue,
                          ),
                          SizedBox(width: r(8)),
                          Flexible(
                            child: Text(
                              'Protected by secure payment processing',
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.montserrat(
                                fontSize: r(11.5),
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
