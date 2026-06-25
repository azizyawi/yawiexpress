import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wanmac/config/api_config.dart';
import 'package:wanmac/controllers/send_package_controller.dart';
import 'package:wanmac/core/providers/location/location_providers.dart';
import 'package:wanmac/core/theme/app_colors.dart';
import 'package:wanmac/core/utils/app_snackbar.dart';
import 'package:wanmac/models/location_model.dart';
import 'package:wanmac/services/location_request_api_service.dart';
import 'package:wanmac/services/location_service.dart';
import 'package:wanmac/services/order_api_service.dart';
import 'package:wanmac/services/order_estimate_api_service.dart';
import 'package:wanmac/views/screens/ReviewPaymentScreen/review_payment_screen.dart';
import 'package:wanmac/views/screens/map/map_location_picker_scren.dart';

import 'address_search_screen.dart';
import 'sheets/delivery_options_sheet.dart';
import 'sheets/pickup_options_sheet.dart';
import 'widgets/fee_tile.dart';
import 'widgets/package_details_section.dart';
import 'widgets/pickup_dropoff_card.dart';
import 'widgets/protection_section.dart';
import 'widgets/receiver_info_section.dart';
import 'widgets/section_header.dart';
import 'widgets/send_package_app_bar.dart';
import 'widgets/sender_info_section.dart';

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

double _maxContentWidth(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  final isTablet = size.shortestSide >= 600;
  final isLandscape =
      MediaQuery.orientationOf(context) == Orientation.landscape;

  if (isTablet && isLandscape) return 900;
  if (isTablet) return 680;
  if (isLandscape) return 760;

  return double.infinity;
}

class SendPackageScreen extends ConsumerStatefulWidget {
  const SendPackageScreen({super.key});

  @override
  ConsumerState<SendPackageScreen> createState() => _SendPackageScreenState();
}

class _SendPackageScreenState extends ConsumerState<SendPackageScreen> {
  bool applyProtection = false;
  String? selectedPackageType;
  late SendPackageController controller;

  int currentStep = 0;

  final List<PackageItem> packageTypes = const [
    PackageItem(label: 'Box', icon: Icons.inventory_2_outlined),
    PackageItem(label: 'Parcel', icon: Icons.card_giftcard_outlined),
    PackageItem(label: 'Perishable', icon: Icons.local_grocery_store_outlined),
    PackageItem(label: 'Food', icon: Icons.fastfood_outlined),
    PackageItem(label: 'Documents', icon: Icons.description_outlined),
    PackageItem(label: 'Medicine', icon: Icons.medication_outlined),
    PackageItem(label: 'Other', icon: Icons.category_outlined),
  ];

  final List<_StepMeta> steps = const [
    _StepMeta(title: 'Locations', icon: Icons.route_outlined),
    _StepMeta(title: 'Person', icon: Icons.people_outline_rounded),
    _StepMeta(title: 'Package', icon: Icons.inventory_2_outlined),
  ];

  @override
  void initState() {
    super.initState();

    controller = SendPackageController(
      LocationService(),
      const LocationRequestApiService(baseUrl: ApiConfig.ordersBaseUrl),
      const OrderEstimateApiService(estimateUrl: ApiConfig.estimateUrl),
      const OrderApiService(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final locationNotifier = ref.read(locationNotifierProvider.notifier);
      var locationState = ref.read(locationNotifierProvider);

      if (locationState.pickupLocation != null) {
        controller.setPickupLocation(
          locationState.pickupLocation!,
          addToRecent: false,
        );
      } else if (locationState.currentLocation != null) {
        locationNotifier.setPickupLocation(locationState.currentLocation!);
        controller.setPickupLocation(
          locationState.currentLocation!,
          addToRecent: false,
        );
      } else {
        await locationNotifier.fetchCurrentLocation();

        if (!mounted) return;

        locationState = ref.read(locationNotifierProvider);

        if (locationState.currentLocation != null) {
          locationNotifier.setPickupLocation(locationState.currentLocation!);
          controller.setPickupLocation(
            locationState.currentLocation!,
            addToRecent: false,
          );
        }
      }

      locationState = ref.read(locationNotifierProvider);

      if (locationState.dropoffLocation != null) {
        controller.setDropoffLocation(
          locationState.dropoffLocation!,
          addToRecent: false,
        );
      }

      if (controller.pickupLocation != null &&
          controller.dropoffLocation != null) {
        await controller.fetchEstimate();
      }

      if (mounted) setState(() {});
    });
  }

  TextStyle _sf({
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

  String _formatAmount(num amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
  }

  String _displayAddress(LocationModel? location, String fallback) {
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

  Future<void> _openPickupAddressScreen() async {
    final selectedLocation = await Navigator.push<LocationModel>(
      context,
      MaterialPageRoute(
        builder: (_) => AddressSearchScreen(
          title: 'Pickup address',
          controller: controller,
          isPickup: true,
        ),
      ),
    );

    if (selectedLocation != null) {
      ref
          .read(locationNotifierProvider.notifier)
          .setPickupLocation(selectedLocation);

      controller.setPickupLocation(selectedLocation, addToRecent: true);

      if (controller.dropoffLocation != null) {
        await controller.fetchEstimate();
      }
    }
  }

  Future<void> _openDeliveryAddressScreen() async {
    final selectedLocation = await Navigator.push<LocationModel>(
      context,
      MaterialPageRoute(
        builder: (_) => AddressSearchScreen(
          title: 'Delivery address',
          controller: controller,
          isPickup: false,
        ),
      ),
    );

    if (selectedLocation != null) {
      ref
          .read(locationNotifierProvider.notifier)
          .setDropoffLocation(selectedLocation);

      controller.setDropoffLocation(selectedLocation, addToRecent: true);

      if (controller.pickupLocation != null) {
        await controller.fetchEstimate();
      }
    }
  }

  Future<void> _openMapPicker({required bool isPickup}) async {
    final locationState = ref.read(locationNotifierProvider);

    final initialLocation = isPickup
        ? locationState.pickupLocation
        : locationState.dropoffLocation;

    final selectedLocation = await Navigator.push<LocationModel>(
      context,
      MaterialPageRoute(
        builder: (_) => MapLocationPickerScreen(
          title: isPickup
              ? 'Choose pickup location'
              : 'Choose delivery location',
          initialLocation: initialLocation,
        ),
      ),
    );

    if (selectedLocation == null) return;

    if (isPickup) {
      ref
          .read(locationNotifierProvider.notifier)
          .setPickupLocation(selectedLocation);

      controller.setPickupLocation(selectedLocation, addToRecent: true);

      if (controller.dropoffLocation != null) {
        await controller.fetchEstimate();
      }
    } else {
      ref
          .read(locationNotifierProvider.notifier)
          .setDropoffLocation(selectedLocation);

      controller.setDropoffLocation(selectedLocation, addToRecent: true);

      if (controller.pickupLocation != null) {
        await controller.fetchEstimate();
      }
    }
  }

  Future<void> _useCurrentLocationForPickup() async {
    final notifier = ref.read(locationNotifierProvider.notifier);

    await notifier.fetchCurrentLocation();

    if (!mounted) return;

    final locationState = ref.read(locationNotifierProvider);
    final location = locationState.currentLocation;

    if (location != null) {
      notifier.setPickupLocation(location);
      controller.setPickupLocation(location, addToRecent: true);

      if (controller.dropoffLocation != null) {
        await controller.fetchEstimate();
      }
    } else if (locationState.error != null) {
      AppSnackBar.show(
        context,
        message: locationState.error!,
        type: AppSnackBarType.error,
      );
    }
  }

  Future<void> _showPickupOptions() async {
    final s = _scale(context);
    double r(double value) => value * s;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(r(28))),
      ),
      builder: (_) {
        return PickupOptionsSheet(
          onUseCurrentLocation: () async {
            Navigator.pop(context);
            await _useCurrentLocationForPickup();
          },
          onSearchAddress: () async {
            Navigator.pop(context);
            await _openPickupAddressScreen();
          },
          onChooseOnMap: () async {
            Navigator.pop(context);
            await _openMapPicker(isPickup: true);
          },
        );
      },
    );
  }

  Future<void> _showDeliveryOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DeliveryOptionsSheet(
          onSearchAddress: () async {
            Navigator.pop(context);
            await _openDeliveryAddressScreen();
          },
          onChooseOnMap: () async {
            Navigator.pop(context);
            await _openMapPicker(isPickup: false);
          },
          onClose: () => Navigator.pop(context),
        );
      },
    );
  }

  bool _validateCurrentStep() {
    final locationState = ref.read(locationNotifierProvider);

    if (currentStep == 0) {
      if (locationState.pickupLocation == null ||
          locationState.dropoffLocation == null) {
        _showSnack('Please set both pickup and drop-off locations');
        return false;
      }
    }

    if (currentStep == 1) {
      if (controller.receiverName.trim().isEmpty ||
          controller.receiverPhone.trim().isEmpty) {
        _showSnack('Please enter receiver name and phone number');
        return false;
      }
    }

    if (currentStep == 2 && selectedPackageType == null) {
      _showSnack('Please select a package type');
      return false;
    }

    return true;
  }

  void _nextStep() {
    if (!_validateCurrentStep()) return;

    if (currentStep == 2) {
      controller.setPackageType(selectedPackageType);
      controller.setApplyProtection(applyProtection);
      controller.setPackageFragile(applyProtection);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReviewPaymentScreen(controller: controller),
        ),
      );
      return;
    }

    setState(() => currentStep += 1);
  }

  void _previousStep() {
    if (currentStep == 0) {
      Navigator.pop(context);
      return;
    }

    setState(() => currentStep -= 1);
  }

  void _jumpToStep(int step) {
    if (step > currentStep) return;
    setState(() => currentStep = step);
  }

  void _showSnack(
    String message, {
    AppSnackBarType type = AppSnackBarType.warning,
  }) {
    AppSnackBar.show(context, message: message, type: type);
  }

  String get _stepSubtitle {
    switch (currentStep) {
      case 0:
        return 'Choose pickup and delivery points';
      case 1:
        return 'Add sender and receiver details';
      case 2:
        return 'Tell us what you are sending';
      default:
        return '';
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final locationState = ref.watch(locationNotifierProvider);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final pickupText = _displayAddress(
          locationState.pickupLocation,
          'Tap to set pickup location',
        );

        final deliveryText = _displayAddress(
          locationState.dropoffLocation,
          'Tap to set delivery location',
        );

        final hasBothLocations =
            locationState.pickupLocation != null &&
            locationState.dropoffLocation != null;

        final amountText = controller.isCalculatingRoute
            ? 'Calculating...'
            : (!hasBothLocations
                  ? '₦0'
                  : controller.totalAmount == null
                  ? 'Calculating...'
                  : '₦${_formatAmount(controller.totalAmount!)}');

        final eta = controller.routeDuration ?? 'Calculating...';

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: const SendPackageAppBar(),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: _maxContentWidth(context),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          r(20),
                          r(10),
                          r(20),
                          r(28),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionHeader(
                              eyebrow: 'Send Package',
                              title: steps[currentStep].title,
                            ),
                            SizedBox(height: r(10)),
                            Text(
                              _stepSubtitle,
                              style: _sf(
                                size: r(13),
                                weight: FontWeight.w600,
                                color: AppColors.textSecondary,
                                height: 1.55,
                              ),
                            ),
                            SizedBox(height: r(24)),
                            _StepProgressHeader(
                              steps: steps,
                              currentStep: currentStep,
                              onStepTapped: _jumpToStep,
                              textStyleBuilder: _sf,
                            ),
                            SizedBox(height: r(24)),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 260),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              child: _buildStepContent(
                                key: ValueKey(currentStep),
                                pickupText: pickupText,
                                deliveryText: deliveryText,
                                amountText: amountText,
                                eta: eta,
                                locationState: locationState,
                              ),
                            ),
                            SizedBox(height: r(18)),
                          ],
                        ),
                      ),
                    ),
                    _BottomActionBar(
                      isFirstStep: currentStep == 0,
                      isLastStep: currentStep == steps.length - 1,
                      onBack: _previousStep,
                      onNext: _nextStep,
                      bottomInset: bottomInset,
                      textStyleBuilder: _sf,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepContent({
    required Key key,
    required String pickupText,
    required String deliveryText,
    required String amountText,
    required String eta,
    required dynamic locationState,
  }) {
    final s = _scale(context);
    double r(double value) => value * s;

    switch (currentStep) {
      case 0:
        return Column(
          key: key,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PickupDropoffCard(
              pickupAddress: pickupText,
              dropoffAddress: deliveryText,
              isGettingCurrentLocation: locationState.isLoading,
              onPickupTap: _showPickupOptions,
              onDropoffTap: _showDeliveryOptions,
            ),
            if (controller.estimatedTimeMin != null ||
                controller.distanceKm != null) ...[
              SizedBox(height: r(14)),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: r(16),
                  vertical: r(14),
                ),
                decoration: BoxDecoration(
                  color: AppColors.brandBlueDark.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(r(24)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      color: AppColors.brandBlueDark,
                      size: r(20),
                    ),
                    SizedBox(width: r(10)),
                    Text(
                      'Delivery in $eta',
                      style: GoogleFonts.montserrat(
                        fontSize: r(13),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(width: r(12)),
                    if (controller.distanceKm != null)
                      Expanded(
                        child: Text(
                          '${controller.distanceKm!.toStringAsFixed(1)} km',
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            fontSize: r(12),
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (locationState.error != null) ...[
              SizedBox(height: r(10)),
              Text(
                locationState.error!,
                style: _sf(
                  size: r(12),
                  weight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
            ],
            if (controller.locationError != null) ...[
              SizedBox(height: r(10)),
              Text(
                controller.locationError!,
                style: _sf(
                  size: r(12),
                  weight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
            ],
            SizedBox(height: r(16)),
            FeeTile(amount: amountText),
            SizedBox(height: r(16)),
          ],
        );

      case 1:
        return Column(
          key: key,
          children: [
            SenderInfoSection(controller: controller),
            SizedBox(height: r(16)),
            ReceiverInfoSection(controller: controller),
          ],
        );

      case 2:
        return Column(
          key: key,
          children: [
            PackageDetailsSection(
              packageTypes: packageTypes,
              selectedPackageType: selectedPackageType,
              onSelected: (value) {
                setState(() => selectedPackageType = value);
              },
            ),
            SizedBox(height: r(16)),
            ProtectionSection(
              applyProtection: applyProtection,
              onToggle: () {
                setState(() => applyProtection = !applyProtection);
              },
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

class _StepMeta {
  final String title;
  final IconData icon;

  const _StepMeta({required this.title, required this.icon});
}

typedef _FontBuilder =
    TextStyle Function({
      required double size,
      FontWeight weight,
      Color color,
      double? height,
      double? letterSpacing,
    });

class _StepProgressHeader extends StatelessWidget {
  final List<_StepMeta> steps;
  final int currentStep;
  final ValueChanged<int> onStepTapped;
  final _FontBuilder textStyleBuilder;

  const _StepProgressHeader({
    required this.steps,
    required this.currentStep,
    required this.onStepTapped,
    required this.textStyleBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(r(999)),
          child: LinearProgressIndicator(
            value: (currentStep + 1) / steps.length,
            minHeight: r(6),
            backgroundColor: AppColors.inputBorder.withOpacity(0.55),
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.brandBlueDark,
            ),
          ),
        ),
        SizedBox(height: r(16)),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: List.generate(steps.length, (index) {
              final isActive = index == currentStep;
              final isCompleted = index < currentStep;

              return Padding(
                padding: EdgeInsets.only(
                  right: index == steps.length - 1 ? 0 : r(10),
                ),
                child: GestureDetector(
                  onTap: () => onStepTapped(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: r(84),
                    padding: EdgeInsets.symmetric(
                      vertical: r(12),
                      horizontal: r(8),
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.brandBlueDark.withOpacity(0.08)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(r(20)),
                      border: Border.all(
                        color: isActive
                            ? AppColors.brandBlueDark
                            : isCompleted
                            ? AppColors.brandBlueDark.withOpacity(0.35)
                            : AppColors.inputBorder,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: AppColors.brandBlueDark.withOpacity(
                                  0.10,
                                ),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.025),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: r(34),
                          height: r(34),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive || isCompleted
                                ? AppColors.brandBlueDark
                                : AppColors.inputFill,
                          ),
                          child: Icon(
                            isCompleted
                                ? Icons.check_rounded
                                : steps[index].icon,
                            size: r(18),
                            color: isActive || isCompleted
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: r(10)),
                        Text(
                          steps[index].title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: textStyleBuilder(
                            size: r(11),
                            weight: FontWeight.w700,
                            color: isActive
                                ? AppColors.brandBlueDark
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final bool isFirstStep;
  final bool isLastStep;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final double bottomInset;
  final _FontBuilder textStyleBuilder;

  const _BottomActionBar({
    required this.isFirstStep,
    required this.isLastStep,
    required this.onBack,
    required this.onNext,
    required this.bottomInset,
    required this.textStyleBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Container(
      padding: EdgeInsets.fromLTRB(
        r(16),
        r(14),
        r(16),
        bottomInset > 0 ? r(10) : r(18),
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.98),
        border: Border(
          top: BorderSide(color: AppColors.inputBorder.withOpacity(0.9)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            final backWidth = totalWidth * 0.33;
            final actionWidth = totalWidth - backWidth - r(12);

            return Row(
              children: [
                SizedBox(
                  width: backWidth,
                  height: r(56),
                  child: OutlinedButton(
                    onPressed: onBack,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.inputBorder),
                      backgroundColor: AppColors.surface,
                      padding: EdgeInsets.symmetric(horizontal: r(10)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(r(18)),
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        isFirstStep ? 'Cancel' : 'Back',
                        maxLines: 1,
                        style: textStyleBuilder(
                          size: r(15),
                          weight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: r(12)),
                SizedBox(
                  width: actionWidth,
                  height: r(58),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(r(20)),
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.brandBlueDark,
                          AppColors.brandBlueDark,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brandBlueDark.withOpacity(0.24),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(r(20)),
                        onTap: onNext,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: r(14)),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    isLastStep
                                        ? 'Review & Confirm'
                                        : 'Continue',
                                    maxLines: 1,
                                    style: textStyleBuilder(
                                      size: r(15),
                                      weight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                  if (isLastStep) ...[
                                    SizedBox(width: r(8)),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: r(18),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
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
