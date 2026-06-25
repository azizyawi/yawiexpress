import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wanmac/core/theme/app_colors.dart';

class ReviewInfoBanner extends StatelessWidget {
  const ReviewInfoBanner({super.key});

  double _scale(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    final isTablet = size.shortestSide >= 600;
    final isShort = size.height < 700;

    if (isTablet) return 1.10;
    if (isShort) return 0.92;

    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Container(
      padding: EdgeInsets.all(r(16)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(r(20)),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: AppColors.brandBlueDark,
            size: r(20),
          ),
          SizedBox(width: r(12)),
          Expanded(
            child: Text(
              'Your parcel service charge has been added. By confirming this delivery, you agree to the terms of service and consent to secure processing.',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.montserrat(
                fontSize: r(12),
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
