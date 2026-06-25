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

class LocationOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const LocationOptionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(r(18)),
      child: Ink(
        padding: EdgeInsets.symmetric(horizontal: r(16), vertical: r(16)),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(r(18)),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: r(42),
              height: r(42),
              decoration: BoxDecoration(
                color: AppColors.brandBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(r(12)),
              ),
              child: Icon(icon, color: AppColors.brandBlue, size: r(22)),
            ),
            SizedBox(width: r(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      fontSize: r(15),
                      fontWeight: FontWeight.w600,
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
              padding: EdgeInsets.only(top: r(10)),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: r(14),
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
