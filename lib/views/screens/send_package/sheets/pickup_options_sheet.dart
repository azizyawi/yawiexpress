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

class PickupOptionsSheet extends StatelessWidget {
  final VoidCallback onUseCurrentLocation;
  final VoidCallback onSearchAddress;
  final VoidCallback onChooseOnMap;

  const PickupOptionsSheet({
    super.key,
    required this.onUseCurrentLocation,
    required this.onSearchAddress,
    required this.onChooseOnMap,
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
              color: Colors.black.withOpacity(0.12),
              blurRadius: 35,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(r(20), r(10), r(20), r(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: r(42),
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
                    child: Text(
                      'Pickup location',
                      style: _text(
                        context,
                        size: 22,
                        weight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(r(16)),
                    onTap: () => Navigator.pop(context),
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
                ],
              ),
              SizedBox(height: r(6)),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Search and select your pickup address',
                  style: _text(
                    context,
                    size: 13,
                    weight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ),
              SizedBox(height: r(18)),
              _RideStyleOptionTile(
                icon: Icons.search_rounded,
                title: 'Search address',
                subtitle: 'Enter pickup address manually',
                onTap: onSearchAddress,
              ),
              SizedBox(height: r(6)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RideStyleOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RideStyleOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    final isCompact = MediaQuery.sizeOf(context).height < 700;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(r(24)),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: r(16), vertical: r(13)),
          decoration: BoxDecoration(
            color: AppColors.brandBlueDark.withOpacity(0.055),
            borderRadius: BorderRadius.circular(r(24)),
            border: Border.all(
              color: AppColors.brandBlueDark.withOpacity(0.12),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: isCompact ? r(46) : r(52),
                height: isCompact ? r(46) : r(52),
                decoration: BoxDecoration(
                  color: AppColors.brandBlueDark,
                  borderRadius: BorderRadius.circular(r(18)),
                ),
                child: Icon(
                  icon,
                  size: isCompact ? r(21) : r(24),
                  color: Colors.white,
                ),
              ),
              SizedBox(width: r(14)),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: r(14.5),
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: r(5)),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: r(12),
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: r(10)),
              Container(
                width: isCompact ? r(32) : r(34),
                height: isCompact ? r(32) : r(34),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(r(13)),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: r(18),
                  color: AppColors.brandBlueDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
