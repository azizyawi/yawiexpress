import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wanmac/controllers/send_package_controller.dart';
import 'package:wanmac/core/theme/app_colors.dart';
import 'package:wanmac/core/utils/app_snackbar.dart';

double _scale(BuildContext context) {
  final size = MediaQuery.sizeOf(context);

  final isTablet = size.shortestSide >= 600;
  final isShort = size.height < 700;

  if (isTablet) return 1.10;
  if (isShort) return 0.92;

  return 1.0;
}

double _maxContentWidth(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  final isTablet = size.shortestSide >= 600;

  if (isTablet) return 680;

  return double.infinity;
}

class PromoScreen extends StatefulWidget {
  final SendPackageController controller;

  const PromoScreen({super.key, required this.controller});

  @override
  State<PromoScreen> createState() => _PromoScreenState();
}

class _PromoScreenState extends State<PromoScreen> {
  final TextEditingController _promoController = TextEditingController();
  bool _isLoading = false;

  bool get _hasText => _promoController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();

    if ((widget.controller.appliedPromoCode ?? '').isNotEmpty) {
      _promoController.text = widget.controller.appliedPromoCode!;
    }

    _promoController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  Future<void> _redeemCode() async {
    final code = _promoController.text.trim().toUpperCase();

    if (code.isEmpty) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final result = await widget.controller.validatePromoCode(code);
      final data = result['data'] as Map<String, dynamic>? ?? {};

      final isValid = data['isValid'] == true;
      final isApplicable = data['isApplicable'] == true;
      final message =
          result['message']?.toString() ?? 'Unable to validate promo';

      if (!mounted) return;

      if (isValid && isApplicable) {
        AppSnackBar.show(
          context,
          message: 'Promo applied successfully',
          type: AppSnackBarType.success,
        );

        Navigator.pop(context);
        return;
      }

      AppSnackBar.show(context, message: message, type: AppSnackBarType.error);
    } catch (e) {
      if (!mounted) return;

      AppSnackBar.show(
        context,
        message: e.toString(),
        type: AppSnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clearPromo() {
    widget.controller.clearPromo();
    setState(() {
      _promoController.clear();
    });

    AppSnackBar.show(
      context,
      message: 'Promo code has been removed',
      type: AppSnackBarType.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    final hasAppliedPromo = (widget.controller.appliedPromoCode ?? '')
        .trim()
        .isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: r(22)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Promotions',
          style: GoogleFonts.montserrat(
            fontSize: r(18),
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: _maxContentWidth(context)),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: r(20), vertical: r(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _promoInput(),
                  SizedBox(height: r(34)),
                  Container(
                    height: r(1),
                    color: AppColors.inputBorder.withOpacity(0.7),
                  ),
                  SizedBox(height: r(28)),
                  Text(
                    _hasText
                        ? 'Redeem code'
                        : 'Your available discounts and promos',
                    style: GoogleFonts.montserrat(
                      fontSize: r(14),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: r(16)),
                  if (_hasText) _redeemTile(),
                  if (!_hasText && hasAppliedPromo) _appliedPromoTile(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _promoInput() {
    final s = _scale(context);
    double r(double value) => value * s;

    return Container(
      constraints: BoxConstraints(minHeight: r(68)),
      padding: EdgeInsets.symmetric(horizontal: r(16)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(r(14)),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            size: r(20),
            color: AppColors.textSecondary,
          ),
          SizedBox(width: r(12)),
          Expanded(
            child: TextField(
              controller: _promoController,
              maxLines: 1,
              textAlignVertical: TextAlignVertical.center,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [UpperCaseTextFormatter()],
              style: GoogleFonts.montserrat(
                fontSize: r(14),
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: 0.8,
              ),
              decoration: InputDecoration(
                hintText: 'Enter promo code',
                hintStyle: GoogleFonts.montserrat(
                  fontSize: r(14),
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          if (_hasText)
            GestureDetector(
              onTap: () => _promoController.clear(),
              child: Icon(
                Icons.close_rounded,
                size: r(18),
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _redeemTile() {
    final s = _scale(context);
    double r(double value) => value * s;

    return InkWell(
      onTap: _isLoading ? null : _redeemCode,
      borderRadius: BorderRadius.circular(r(14)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: r(16), vertical: r(16)),
        decoration: BoxDecoration(
          color: AppColors.infoBg,
          borderRadius: BorderRadius.circular(r(14)),
          border: Border.all(color: AppColors.infoBorder),
        ),
        child: Row(
          children: [
            Container(
              width: r(38),
              height: r(38),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(r(10)),
              ),
              child: _isLoading
                  ? Center(
                      child: SizedBox(
                        width: r(16),
                        height: r(16),
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Icon(
                      Icons.local_offer_outlined,
                      color: AppColors.brandBlue,
                      size: r(18),
                    ),
            ),
            SizedBox(width: r(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _promoController.text.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: r(13),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  SizedBox(height: r(4)),
                  Text(
                    _isLoading
                        ? 'Validating code...'
                        : 'Tap to redeem this code',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: r(11.5),
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: r(16),
              color: AppColors.brandBlue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _appliedPromoTile() {
    final s = _scale(context);
    double r(double value) => value * s;

    final code = widget.controller.appliedPromoCode ?? '';
    final discount = widget.controller.promoDiscount;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: r(16), vertical: r(16)),
      decoration: BoxDecoration(
        color: AppColors.infoBg,
        borderRadius: BorderRadius.circular(r(14)),
        border: Border.all(color: AppColors.infoBorder),
      ),
      child: Row(
        children: [
          Container(
            width: r(38),
            height: r(38),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(r(10)),
            ),
            child: Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.brandBlue,
              size: r(18),
            ),
          ),
          SizedBox(width: r(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  code,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: r(13),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: r(4)),
                Text(
                  'Discount applied: ₦${discount.toStringAsFixed(0)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: r(11.5),
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _clearPromo,
            child: Text(
              'Remove',
              style: GoogleFonts.montserrat(
                fontSize: r(12),
                fontWeight: FontWeight.w700,
                color: AppColors.brandBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}
