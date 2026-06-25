import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wanmac/core/theme/app_colors.dart';

TextStyle sf({
  required double size,
  FontWeight weight = FontWeight.w500,
  Color color = AppColors.textPrimary,
  double? height,
  double? letterSpacing,
}) {
  return GoogleFonts.montserrat(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}
