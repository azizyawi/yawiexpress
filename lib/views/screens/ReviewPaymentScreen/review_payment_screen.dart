import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wanmac/controllers/send_package_controller.dart';
import 'package:wanmac/core/providers/location/location_providers.dart';
import 'package:wanmac/core/theme/app_colors.dart';
import 'package:wanmac/core/utils/app_snackbar.dart';
import 'package:wanmac/services/order_api_service.dart';
import 'package:wanmac/views/screens/OrderTrackingScreen/order_tracking_screen.dart';
import 'package:wanmac/views/screens/ReviewPaymentScreen/widgets/review_bottom_bar.dart';
import 'package:wanmac/views/screens/ReviewPaymentScreen/widgets/review_detail_tile.dart';
import 'package:wanmac/views/screens/ReviewPaymentScreen/widgets/review_eta_tile.dart';
import 'package:wanmac/views/screens/ReviewPaymentScreen/widgets/review_info_banner.dart';
import 'package:wanmac/views/screens/ReviewPaymentScreen/widgets/review_payment_method_tile.dart';
import 'package:wanmac/views/screens/ReviewPaymentScreen/widgets/review_payment_summary.dart';
import 'package:wanmac/views/screens/ReviewPaymentScreen/widgets/review_progress_hint.dart';
import 'package:wanmac/views/screens/ReviewPaymentScreen/widgets/review_section_card.dart';

class ReviewPaymentScreen extends ConsumerStatefulWidget {
  final SendPackageController controller;

  const ReviewPaymentScreen({super.key, required this.controller});

  @override
  ConsumerState<ReviewPaymentScreen> createState() =>
      _ReviewPaymentScreenState();
}

class _ReviewPaymentScreenState extends ConsumerState<ReviewPaymentScreen> {
  int selectedPaymentMethod = 1;

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

  String _resolveBackendPaymentMethod() {
    return 'cash_on_delivery';
  }

  String _displayAddress(dynamic location, String fallback) {
    if (location == null) return fallback;

    final name = location.name?.trim() ?? '';
    final address = location.address.trim();
    final shortAddress = location.shortAddress?.trim() ?? '';

    if (name.isNotEmpty && address.isNotEmpty) {
      return '$name, $address';
    }

    if (name.isNotEmpty && shortAddress.isNotEmpty) {
      return '$name, $shortAddress';
    }

    if (name.isNotEmpty) return name;
    if (address.isNotEmpty) return address;
    if (shortAddress.isNotEmpty) return shortAddress;

    return fallback;
  }

  Future<void> _handleConfirmDelivery() async {
    if (widget.controller.isCreatingOrder) return;

    final paymentMethod = _resolveBackendPaymentMethod();
    widget.controller.setPaymentMethod(paymentMethod);

    try {
      final created = await widget.controller.createOrderOnly();

      if (!mounted) return;

      if (created) {
        final orderId = widget.controller.createdOrderId;

        if (orderId == null || orderId.isEmpty) {
          AppSnackBar.show(
            context,
            message: 'Order created, but order ID was not returned',
            type: AppSnackBarType.error,
          );
          return;
        }

        final pickup = widget.controller.pickupLocation;
        widget.controller.resetExceptPickup(pickup);

        final locationNotifier = ref.read(locationNotifierProvider.notifier);
        locationNotifier.clearDropoffLocation();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderTrackingScreen(
              orderId: orderId,
              orderApiService: const OrderApiService(),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      AppSnackBar.show(
        context,
        message: widget.controller.paymentError ?? e.toString(),
        type: AppSnackBarType.error,
      );
    }
  }

  Widget _sectionDivider(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: r(16)),
      child: Container(height: 1, color: AppColors.inputBorder),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    final textTheme = GoogleFonts.montserratTextTheme(
      Theme.of(context).textTheme,
    );

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final receiverName = widget.controller.receiverName.trim().isEmpty
            ? 'No receiver name'
            : widget.controller.receiverName.trim();

        final receiverPhone = widget.controller.receiverPhone.trim().isEmpty
            ? 'No phone number'
            : '${widget.controller.receiverCode}${widget.controller.receiverPhone}';

        final receiverEmail = widget.controller.receiverEmail.trim();

        final receiverSubtitle = receiverEmail.isEmpty
            ? receiverPhone
            : '$receiverPhone  •  $receiverEmail';

        final senderName = widget.controller.senderName.trim().isEmpty
            ? 'No sender name'
            : widget.controller.senderName.trim();

        final senderPhone = widget.controller.senderPhone.trim().isEmpty
            ? 'No sender phone'
            : '${widget.controller.senderCode}${widget.controller.senderPhone}';

        final senderEmail = widget.controller.senderEmail.trim();

        final senderSubtitle = senderEmail.isEmpty
            ? senderPhone
            : '$senderPhone  •  $senderEmail';

        final pickupAddress = _displayAddress(
          widget.controller.pickupLocation,
          widget.controller.pickupAddress ?? 'No pickup address selected',
        );

        final dropoffAddress = _displayAddress(
          widget.controller.dropoffLocation,
          widget.controller.dropoffAddress ?? 'No dropoff address selected',
        );

        final deliveryFee = widget.controller.deliveryFee ?? 0;
        final eta = widget.controller.routeDuration ?? 'Calculating...';
        final serviceFee = widget.controller.serviceFee ?? 0;
        final totalPayable = widget.controller.payableAmount;
        final promoDiscount = widget.controller.promoDiscount;
        final appliedPromoCode = widget.controller.appliedPromoCode;

        final isBusy = widget.controller.isCreatingOrder;

        return Theme(
          data: Theme.of(context).copyWith(
            textTheme: textTheme,
            scaffoldBackgroundColor: AppColors.background,
          ),
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: AppColors.background,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, size: r(18)),
                color: AppColors.textPrimary,
                onPressed: isBusy ? null : () => Navigator.pop(context),
              ),
              titleSpacing: 0,
              title: Text(
                'Review & Payment',
                style: GoogleFonts.montserrat(
                  fontSize: r(20),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            body: SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: _maxContentWidth(context),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.fromLTRB(
                            r(20),
                            r(8),
                            r(20),
                            r(24),
                          ),
                          children: [
                            const ReviewProgressHint(),
                            SizedBox(height: r(24)),
                            ReviewSectionCard(
                              title: 'Shipment overview',
                              child: Column(
                                children: [
                                  ReviewDetailTile(
                                    icon: Icons.north_east_rounded,
                                    label: 'Sender',
                                    value: senderName,
                                    subtitle: senderSubtitle,
                                  ),
                                  _sectionDivider(context),
                                  ReviewDetailTile(
                                    icon: Icons.location_on_outlined,
                                    label: 'Pickup address',
                                    value: pickupAddress,
                                  ),
                                  _sectionDivider(context),
                                  ReviewDetailTile(
                                    icon: Icons.south_west_rounded,
                                    label: 'Receiver',
                                    value: receiverName,
                                    subtitle: receiverSubtitle,
                                  ),
                                  _sectionDivider(context),
                                  ReviewDetailTile(
                                    icon: Icons.place_outlined,
                                    label: 'Dropoff address',
                                    value: dropoffAddress,
                                  ),
                                  _sectionDivider(context),
                                  ReviewEtaTile(
                                    eta: eta,
                                    subtitle: 'May vary due to traffic',
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: r(18)),
                            ReviewPaymentSummary(
                              controller: widget.controller,
                              deliveryFee: deliveryFee,
                              serviceFee: serviceFee,
                              totalPayable: totalPayable,
                              promoDiscount: promoDiscount,
                              appliedPromoCode: appliedPromoCode,
                            ),
                            SizedBox(height: r(18)),
                            ReviewSectionCard(
                              title: 'Payment method',
                              child: Column(
                                children: [
                                  ReviewPaymentMethodTile(
                                    index: 1,
                                    selectedPaymentMethod:
                                        selectedPaymentMethod,
                                    icon: Icons.money_rounded,
                                    title: 'Cash on delivery',
                                    subtitle:
                                        'Pay with cash when your package is delivered',
                                    isBusy: isBusy,
                                    onTap: () {
                                      setState(() {
                                        selectedPaymentMethod = 1;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: r(18)),
                            if ((widget.controller.paymentError ?? '')
                                .isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(bottom: r(18)),
                                child: Container(
                                  padding: EdgeInsets.all(r(14)),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(r(16)),
                                    border: Border.all(
                                      color: AppColors.error.withOpacity(0.22),
                                    ),
                                  ),
                                  child: Text(
                                    widget.controller.paymentError!,
                                    style: GoogleFonts.montserrat(
                                      fontSize: r(12),
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                              ),
                            const ReviewInfoBanner(),
                          ],
                        ),
                      ),
                      ReviewBottomBar(
                        totalPayable: totalPayable,
                        isBusy: isBusy,
                        onPressed: _handleConfirmDelivery,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
