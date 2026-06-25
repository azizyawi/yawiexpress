import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wanmac/core/theme/app_colors.dart';

class ReviewEtaTile extends StatelessWidget {
  final String eta;
  final String? subtitle;

  const ReviewEtaTile({super.key, required this.eta, this.subtitle});

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
      width: double.infinity,
      padding: EdgeInsets.all(r(14)),
      decoration: BoxDecoration(
        color: AppColors.brandBlueDark.withOpacity(0.06),
        borderRadius: BorderRadius.circular(r(16)),
        border: Border.all(color: AppColors.brandBlueDark.withOpacity(0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: r(40),
            width: r(40),
            decoration: BoxDecoration(
              color: AppColors.brandBlueDark.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.schedule_rounded,
              color: AppColors.brandBlueDark,
              size: r(20),
            ),
          ),
          SizedBox(width: r(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimated delivery time after pickup',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: r(12),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: r(4)),
                Text(
                  eta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: r(16),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  SizedBox(height: r(4)),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: r(11),
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
