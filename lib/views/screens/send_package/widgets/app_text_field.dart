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

class AppTextField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final IconData? icon;

  const AppTextField({
    super.key,
    required this.label,
    required this.hintText,
    this.keyboardType,
    this.controller,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    OutlineInputBorder border(Color color) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(r(22)),
        borderSide: BorderSide(color: color, width: 1.5),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: r(12),
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.1,
          ),
        ),
        SizedBox(height: r(8)),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.montserrat(
            fontSize: r(14),
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.montserrat(
              fontSize: r(13),
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary.withOpacity(0.65),
            ),
            filled: true,
            fillColor: const Color(0xFFF7F8FA),
            contentPadding: EdgeInsets.symmetric(
              horizontal: r(18),
              vertical: r(18),
            ),
            prefixIcon: icon == null
                ? null
                : Icon(icon, size: r(20), color: AppColors.textSecondary),
            border: border(AppColors.brandBlueDark),
            enabledBorder: border(AppColors.brandBlueDark),
            focusedBorder: border(AppColors.brandBlueDark),
            errorBorder: border(Colors.redAccent),
            focusedErrorBorder: border(Colors.redAccent),
          ),
        ),
      ],
    );
  }
}
