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

class CheckRowModern extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final VoidCallback onChanged;

  const CheckRowModern({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return GestureDetector(
      onTap: onChanged,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: r(14), vertical: r(14)),
        decoration: BoxDecoration(
          color: value
              ? AppColors.brandBlue.withValues(alpha: 0.06)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(r(14)),
          border: Border.all(
            color: value
                ? AppColors.brandBlue.withValues(alpha: 0.28)
                : AppColors.inputBorder.withValues(alpha: 0.85),
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: r(22),
              height: r(22),
              decoration: BoxDecoration(
                color: value ? AppColors.brandBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(r(6)),
                border: Border.all(
                  color: value ? AppColors.brandBlue : AppColors.inputBorder,
                  width: 1.5,
                ),
              ),
              child: value
                  ? Icon(Icons.check_rounded, size: r(14), color: Colors.white)
                  : null,
            ),
            SizedBox(width: r(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      fontSize: r(13.5),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: r(3)),
                  Text(
                    subtitle,
                    style: GoogleFonts.montserrat(
                      fontSize: r(11.8),
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
