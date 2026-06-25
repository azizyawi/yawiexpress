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

class FeeTile extends StatelessWidget {
  final String label;
  final String amount;

  const FeeTile({
    super.key,
    this.label = 'Delivery fee:',
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: r(16), vertical: r(16)),
      decoration: BoxDecoration(
        color: AppColors.infoBg,
        borderRadius: BorderRadius.circular(r(12)),
        border: Border.all(color: AppColors.infoBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: r(14),
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(width: r(12)),
          Text(
            amount,
            style: GoogleFonts.montserrat(
              fontSize: r(15),
              fontWeight: FontWeight.w700,
              color: AppColors.brandBlue,
            ),
          ),
        ],
      ),
    );
  }
}
