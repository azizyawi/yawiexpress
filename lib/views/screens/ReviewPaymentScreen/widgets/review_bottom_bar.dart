import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wanmac/core/theme/app_colors.dart';

class ReviewBottomBar extends StatelessWidget {
  final double totalPayable;
  final bool isBusy;
  final VoidCallback onPressed;

  const ReviewBottomBar({
    super.key,
    required this.totalPayable,
    required this.isBusy,
    required this.onPressed,
  });

  double _scale(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    final isTablet = size.shortestSide >= 600;
    final isShort = size.height < 700;

    if (isTablet) return 1.10;
    if (isShort) return 0.92;

    return 1.0;
  }

  String _formatAmount(num amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
  }

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    final totalAmount = '₦${_formatAmount(totalPayable)}';

    return Container(
      padding: EdgeInsets.fromLTRB(r(20), r(16), r(20), r(24)),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(.98),
        border: Border(top: BorderSide(color: AppColors.inputBorder)),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(.04),
            blurRadius: r(20),
            offset: Offset(0, -r(6)),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 360;

            if (isNarrow) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Total payable',
                    style: GoogleFonts.montserrat(
                      fontSize: r(12),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: r(4)),
                  Text(
                    totalAmount,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: r(24),
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -1,
                    ),
                  ),
                  SizedBox(height: r(16)),
                  SizedBox(
                    height: r(56),
                    child: ElevatedButton(
                      onPressed: isBusy ? null : onPressed,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: AppColors.brandBlueDark,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(r(18)),
                        ),
                      ),
                      child: isBusy
                          ? SizedBox(
                              width: r(20),
                              height: r(20),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Confirm Delivery',
                              style: GoogleFonts.montserrat(
                                fontSize: r(14),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.1,
                              ),
                            ),
                    ),
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total payable',
                        style: GoogleFonts.montserrat(
                          fontSize: r(12),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: r(4)),
                      Text(
                        totalAmount,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: r(26),
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: r(16)),
                SizedBox(
                  width: r(180),
                  height: r(56),
                  child: ElevatedButton(
                    onPressed: isBusy ? null : onPressed,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.brandBlueDark,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(r(18)),
                      ),
                    ),
                    child: isBusy
                        ? SizedBox(
                            width: r(20),
                            height: r(20),
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Confirm Delivery',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(
                              fontSize: r(14),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                            ),
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
