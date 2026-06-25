import 'package:flutter/material.dart';
import 'package:wanmac/core/theme/app_colors.dart';

class HomeInnerDivider extends StatelessWidget {
  const HomeInnerDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.inputBorder.withOpacity(0.55),
    );
  }
}
