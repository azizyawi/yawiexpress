import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wanmac/controllers/send_package_controller.dart';
import 'package:wanmac/core/theme/app_colors.dart';
import 'package:wanmac/views/screens/ReviewPaymentScreen/widgets/review_section_card.dart';
import 'package:wanmac/views/screens/order/promo_screen.dart';

class ReviewPaymentSummary extends StatelessWidget {
  final SendPackageController controller;
  final double deliveryFee;
  final double serviceFee;
  final double totalPayable;
  final double promoDiscount;
  final String? appliedPromoCode;

  const ReviewPaymentSummary({
    super.key,
    required this.controller,
    required this.deliveryFee,
    required this.serviceFee,
    required this.totalPayable,
    this.promoDiscount = 0,
    this.appliedPromoCode,
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

  Widget _amountRow(
    BuildContext context,
    String label,
    String value, {
    bool highlight = false,
  }) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              fontSize: highlight ? r(13) : r(12.5),
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
              color: highlight ? AppColors.label : AppColors.textSecondary,
              letterSpacing: 0.1,
            ),
          ),
        ),
        SizedBox(width: r(12)),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: GoogleFonts.montserrat(
              fontSize: highlight ? r(24) : r(15),
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: highlight ? -0.8 : -0.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _promoRow(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    final hasPromo = appliedPromoCode != null && appliedPromoCode!.isNotEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(r(18)),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PromoScreen(controller: controller),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: r(14), vertical: r(14)),
        decoration: BoxDecoration(
          color: AppColors.infoBg,
          borderRadius: BorderRadius.circular(r(18)),
          border: Border.all(color: AppColors.infoBorder),
        ),
        child: Row(
          children: [
            Container(
              width: r(38),
              height: r(38),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(r(12)),
              ),
              child: Icon(
                Icons.local_offer_outlined,
                color: AppColors.brandBlueDark,
                size: r(18),
              ),
            ),
            SizedBox(width: r(12)),
            Expanded(
              child: Text(
                hasPromo
                    ? 'Promo applied: ${appliedPromoCode!}'
                    : 'Apply promo code or rewards for this delivery',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  fontSize: r(12.5),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.45,
                ),
              ),
            ),
            SizedBox(width: r(10)),
            Icon(
              Icons.keyboard_arrow_right_rounded,
              color: AppColors.brandBlueDark,
              size: r(24),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return ReviewSectionCard(
      title: 'Payment summary',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _promoRow(context),
          SizedBox(height: r(18)),
          _amountRow(context, 'Delivery fee', '₦${_formatAmount(deliveryFee)}'),
          SizedBox(height: r(12)),
          _amountRow(context, 'Service fee', '₦${_formatAmount(serviceFee)}'),
          if (promoDiscount > 0) ...[
            SizedBox(height: r(12)),
            _amountRow(
              context,
              appliedPromoCode == null
                  ? 'Promo discount'
                  : 'Promo (${appliedPromoCode!})',
              '-₦${_formatAmount(promoDiscount)}',
            ),
          ],
          SizedBox(height: r(16)),
          Container(height: 1, color: AppColors.inputBorder),
          SizedBox(height: r(16)),
          _amountRow(
            context,
            'Total payable',
            '₦${_formatAmount(totalPayable)}',
            highlight: true,
          ),
        ],
      ),
    );
  }
}
