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

class SectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;

  const SectionHeader({super.key, required this.eyebrow, required this.title});

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: GoogleFonts.montserrat(
            fontSize: r(11.5),
            fontWeight: FontWeight.w700,
            color: AppColors.brandBlue,
            letterSpacing: 1.1,
          ),
        ),
        SizedBox(height: r(8)),
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: r(22),
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            height: 1.25,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }
}
