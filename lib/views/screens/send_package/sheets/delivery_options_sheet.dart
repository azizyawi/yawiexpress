import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wanmac/core/theme/app_colors.dart';

double _scale(BuildContext context) {
  final size = MediaQuery.sizeOf(context);

  final isTablet = size.shortestSide >= 600;
  final isLandscape =
      MediaQuery.orientationOf(context) == Orientation.landscape;
  final isShort = size.height < 700;

  if (isTablet) return 1.10;
  if (isLandscape || isShort) return 0.92;

  return 1.0;
}

class DeliveryOptionsSheet extends StatelessWidget {
  final VoidCallback onSearchAddress;
  final VoidCallback onChooseOnMap;
  final VoidCallback onClose;

  const DeliveryOptionsSheet({
    super.key,
    required this.onSearchAddress,
    required this.onChooseOnMap,
    required this.onClose,
  });

  TextStyle _text(
    BuildContext context, {
    required double size,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.textPrimary,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.montserrat(
      fontSize: size * _scale(context),
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(r(30))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 40,
              offset: const Offset(0, -12),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(r(20), r(10), r(20), r(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: r(38),
                height: r(5),
                decoration: BoxDecoration(
                  color: AppColors.inputBorder.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(r(100)),
                ),
              ),
              SizedBox(height: r(18)),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivery location',
                          style: _text(
                            context,
                            size: 21,
                            weight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                        ),
                        SizedBox(height: r(4)),
                        Text(
                          'Choose how you want to set the drop-off point',
                          style: _text(
                            context,
                            size: 13,
                            weight: FontWeight.w500,
                            color: AppColors.textSecondary,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(r(16)),
                      onTap: onClose,
                      child: Container(
                        width: r(40),
                        height: r(40),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(r(16)),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: r(20),
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: r(22)),
              _PremiumDeliveryOption(
                icon: Icons.search_rounded,
                title: 'Search address',
                subtitle: 'Enter the delivery address manually',
                highlighted: true,
                onTap: onSearchAddress,
              ),
              SizedBox(height: r(12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumDeliveryOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool highlighted;
  final VoidCallback onTap;

  const _PremiumDeliveryOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    final bgColor = highlighted
        ? AppColors.brandBlueDark.withOpacity(0.06)
        : AppColors.background;

    final borderColor = highlighted
        ? AppColors.brandBlueDark.withOpacity(0.18)
        : AppColors.inputBorder.withOpacity(0.7);

    final iconBg = highlighted ? AppColors.brandBlueDark : AppColors.surface;
    final iconColor = highlighted ? Colors.white : AppColors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(r(20)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(horizontal: r(14), vertical: r(14)),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(r(20)),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: r(48),
                height: r(48),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(r(16)),
                ),
                child: Icon(icon, size: r(22), color: iconColor),
              ),
              SizedBox(width: r(14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.montserrat(
                        fontSize: r(14),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.1,
                      ),
                    ),
                    SizedBox(height: r(4)),
                    Text(
                      subtitle,
                      style: GoogleFonts.montserrat(
                        fontSize: r(12),
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: r(10)),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: r(15),
                color: AppColors.textSecondary.withOpacity(0.85),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
