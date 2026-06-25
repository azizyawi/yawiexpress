import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wanmac/core/theme/app_colors.dart';

class ReviewDetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;

  const ReviewDetailTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
  });

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

    return Padding(
      padding: EdgeInsets.symmetric(vertical: r(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: r(44),
            height: r(44),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(r(12)),
            ),
            child: Icon(icon, size: r(20), color: AppColors.brandBlueDark),
          ),
          SizedBox(width: r(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: r(10),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AppColors.textHint,
                  ),
                ),
                SizedBox(height: r(6)),
                Text(
                  value,
                  style: GoogleFonts.montserrat(
                    fontSize: r(16),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  SizedBox(height: r(5)),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: r(13),
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      height: 1.5,
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
