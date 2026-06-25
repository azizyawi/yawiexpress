import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

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

class SoftSection extends StatelessWidget {
  final String title;
  final Widget child;

  const SoftSection({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(r(18)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(r(22)),
        border: Border.all(color: AppColors.inputBorder.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: r(15.5),
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: r(18)),
          child,
        ],
      ),
    );
  }
}
