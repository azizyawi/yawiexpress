import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wanmac/core/theme/app_colors.dart';

class ReviewPaymentMethodTile extends StatelessWidget {
  final int index;
  final int selectedPaymentMethod;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isBusy;
  final String? trailingText;
  final VoidCallback onTap;

  const ReviewPaymentMethodTile({
    super.key,
    required this.index,
    required this.selectedPaymentMethod,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isBusy,
    required this.onTap,
    this.trailingText,
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

    final isSelected = selectedPaymentMethod == index;

    return InkWell(
      borderRadius: BorderRadius.circular(r(18)),
      onTap: isBusy ? null : onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: r(14), vertical: r(14)),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandBlueDark.withOpacity(.05)
              : AppColors.inputFill,
          borderRadius: BorderRadius.circular(r(18)),
          border: Border.all(
            color: isSelected
                ? AppColors.brandBlueDark.withOpacity(.35)
                : AppColors.inputBorder.withOpacity(.7),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: r(42),
              height: r(42),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(r(14)),
              ),
              child: Icon(icon, size: r(20), color: AppColors.brandBlueDark),
            ),
            SizedBox(width: r(13)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: r(14),
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: r(4)),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: r(12),
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (trailingText != null) ...[
              SizedBox(width: r(8)),
              Flexible(
                child: Text(
                  trailingText!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: r(12),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
            SizedBox(width: r(8)),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: r(24),
              color: isSelected ? AppColors.brandBlueDark : AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}
