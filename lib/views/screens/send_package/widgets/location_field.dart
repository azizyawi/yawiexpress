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

class LocationField extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool isHint;

  const LocationField({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.isHint = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: r(14),
            fontWeight: FontWeight.w600,
            color: AppColors.label,
          ),
        ),
        SizedBox(height: r(8)),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: r(12), vertical: r(16)),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(r(12)),
            border: Border.all(color: AppColors.brandBlueDark, width: 1.5),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: r(18),
                color: isHint ? AppColors.textHint : AppColors.brandBlue,
              ),
              SizedBox(width: r(8)),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    value,
                    maxLines: 1,
                    softWrap: false,
                    style: GoogleFonts.montserrat(
                      fontSize: r(12.5),
                      fontWeight: FontWeight.w500,
                      color: isHint
                          ? AppColors.textHint
                          : AppColors.textPrimary,
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
