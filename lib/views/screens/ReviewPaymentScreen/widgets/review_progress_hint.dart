import 'package:flutter/material.dart';
import 'package:wanmac/core/theme/app_colors.dart';

class ReviewProgressHint extends StatelessWidget {
  const ReviewProgressHint({super.key});

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

    return Row(
      children: [
        Expanded(
          child: Container(
            height: r(4),
            decoration: BoxDecoration(
              color: AppColors.brandBlueDark,
              borderRadius: BorderRadius.circular(r(999)),
            ),
          ),
        ),
        SizedBox(width: r(8)),
        Expanded(
          child: Container(
            height: r(4),
            decoration: BoxDecoration(
              color: AppColors.brandBlueDark.withOpacity(.18),
              borderRadius: BorderRadius.circular(r(999)),
            ),
          ),
        ),
      ],
    );
  }
}
