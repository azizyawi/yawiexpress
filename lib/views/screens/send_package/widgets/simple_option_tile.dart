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

class SimpleOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool highlighted;
  final String? badge;

  const SimpleOptionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlighted = false,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(r(18)),
      child: Ink(
        padding: EdgeInsets.symmetric(horizontal: r(14), vertical: r(14)),
        decoration: BoxDecoration(
          color: highlighted
              ? AppColors.brandBlue.withOpacity(0.05)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(r(18)),
          border: Border.all(
            color: highlighted
                ? AppColors.brandBlue.withOpacity(0.18)
                : AppColors.inputBorder,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: r(44),
              height: r(44),
              decoration: BoxDecoration(
                color: highlighted
                    ? AppColors.brandBlue.withOpacity(0.10)
                    : AppColors.inputFill,
                borderRadius: BorderRadius.circular(r(13)),
              ),
              child: Icon(
                icon,
                size: r(21),
                color: highlighted
                    ? AppColors.brandBlue
                    : AppColors.textPrimary,
              ),
            ),
            SizedBox(width: r(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (badge != null) ...[
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: r(8),
                        vertical: r(4),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.infoBg,
                        borderRadius: BorderRadius.circular(r(999)),
                        border: Border.all(color: AppColors.infoBorder),
                      ),
                      child: Text(
                        badge!,
                        style: GoogleFonts.montserrat(
                          fontSize: r(10),
                          fontWeight: FontWeight.w700,
                          color: AppColors.brandBlue,
                        ),
                      ),
                    ),
                    SizedBox(height: r(8)),
                  ],
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      fontSize: r(14),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: r(4)),
                  Text(
                    subtitle,
                    style: GoogleFonts.montserrat(
                      fontSize: r(12),
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: r(8)),
            Padding(
              padding: EdgeInsets.only(top: r(12)),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: r(14),
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
