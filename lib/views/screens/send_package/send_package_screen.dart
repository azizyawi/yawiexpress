import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import 'address_search_screen.dart';


class SendPackageScreen extends ConsumerStatefulWidget {
  const SendPackageScreen({super.key});
  @override
  ConsumerState<SendPackageScreen> createState() => _SendPackageScreenState();
}

class _SendPackageScreenState extends ConsumerState<SendPackageScreen> {
  late final SendPackageController controller;
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _sending = true;
  bool _loadingProfile = true;
  bool _reviewing = false;
  int _step = 0;
  String _accountName = '', _accountPhone = '', _accountEmail = '';
  String? _profileError;
  String _recipientName = '', _recipientPhone = '';
  String _senderName = '', _senderPhone = '';
  String _packageType = 'Parcel';

  @override
  void initState() {
    super.initState();
    controller = SendPackageController(
      LocationService(),
      const LocationRequestApiService(baseUrl: ApiConfig.ordersBaseUrl),
      const OrderEstimateApiService(estimateUrl: ApiConfig.estimateUrl),
      const OrderApiService(),
    );
    _loadProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final locations = ref.read(locationNotifierProvider);
      if (locations.pickupLocation != null) {
        controller.setPickupLocation(locations.pickupLocation!, addToRecent: false);
      }
      if (locations.dropoffLocation != null) {
        controller.setDropoffLocation(locations.dropoffLocation!, addToRecent: false);
      }
      // Do not assume the user's current location is the sender's address.
      if (controller.pickupLocation != null && controller.dropoffLocation != null) {
        controller.fetchEstimate();
      }
    });
  }

  Future<void> _loadProfile() async {
    setState(() { _loadingProfile = true; _profileError = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      _accountName = '${prefs.getString('firstName') ?? ''} ${prefs.getString('lastName') ?? ''}'.trim();
      _accountPhone = prefs.getString('phoneNumber') ?? '';
      _accountEmail = prefs.getString('email') ?? '';
      controller.setCurrentUserId(prefs.getString('userId') ?? '');
      if (_accountName.isEmpty || _normalizedPhone(_accountPhone) == null || controller.currentUserId.isEmpty) {
        _profileError = 'Please complete your name and phone number in your account, then return here.';
      }
    } catch (_) {
      if (!mounted) return;
      _profileError = 'Could not load your account details. Please try again.';
    }
    if (mounted) setState(() => _loadingProfile = false);
  }

  String? _normalizedPhone(String raw) {
    final value = raw.replaceAll(RegExp(r'[\s()\-]'), '');
    if (RegExp(r'^0[789]\d{9}$').hasMatch(value)) return '+234${value.substring(1)}';
    if (RegExp(r'^[789]\d{9}$').hasMatch(value)) return '+234$value';
    if (RegExp(r'^234[789]\d{9}$').hasMatch(value)) return '+$value';
    if (RegExp(r'^\+234[789]\d{9}$').hasMatch(value)) return value;
    if (!value.startsWith('+234') && RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(value)) return value;
    return null;
  }

  void _setMode(bool sending) {
    if (_sending == sending) return;
    if (_sending) { _recipientName = _name.text; _recipientPhone = _phone.text; }
    else { _senderName = _name.text; _senderPhone = _phone.text; }
    setState(() {
      _sending = sending;
      _step = 0;
      _name.text = sending ? _recipientName : _senderName;
      _phone.text = sending ? _recipientPhone : _senderPhone;
    });
    // Addresses keep their literal pickup/drop-off meaning; never swap them.
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

    if (!mounted) return;
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

    if (!mounted) return;
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

  Future<void> _next() async {
    if (_loadingProfile || _reviewing || controller.isCalculatingRoute) return;
    if (_profileError != null) { _showSnack(_profileError!); return; }
    if (controller.pickupLocation == null || controller.dropoffLocation == null) {
      _showSnack('Please choose pickup and drop-off addresses'); return;
    }
    if (controller.totalAmount == null) {
      await controller.fetchEstimate();
      if (!mounted) return;
      if (controller.totalAmount == null) {
        _showSnack('Could not get the delivery fee. Please try again.'); return;
      }
    }
    if (_step == 0) { setState(() => _step = 1); return; }
    if (!(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final otherPhone = _normalizedPhone(_phone.text)!;
    final ownPhone = _normalizedPhone(_accountPhone)!;
    controller.setSenderName(_sending ? _accountName : _name.text.trim());
    controller.setSenderPhone(_sending ? ownPhone : otherPhone);
    controller.setSenderCode('+234');
    controller.setSenderEmail(_sending ? _accountEmail : '');
    controller.setReceiverName(_sending ? _name.text.trim() : _accountName);
    controller.setReceiverPhone(_sending ? otherPhone : ownPhone);
    controller.setReceiverCode('+234');
    controller.setReceiverEmail(_sending ? '' : _accountEmail);
    controller.setPackageType(_packageType);
    controller.setPackageDescription(_packageType);
    controller.resetPaymentState(keepCreatedOrder: false);
    setState(() => _reviewing = true);
    try {
      await Navigator.push(context, MaterialPageRoute(
        builder: (_) => ReviewPaymentScreen(controller: controller),
      ));
    } finally {
      if (mounted) setState(() => _reviewing = false);
    }
  }

  void _showSnack(String message) => AppSnackBar.show(
    context, message: message, type: AppSnackBarType.warning,
  );

  @override
  void dispose() {
    _name.dispose(); _phone.dispose(); controller.dispose(); super.dispose();
  }

  Widget _tab(String label, bool sending) => Expanded(
    child: Semantics(
      selected: _sending == sending,
      child: TextButton(
        onPressed: _reviewing ? null : () => _setMode(sending),
        style: TextButton.styleFrom(
          backgroundColor: _sending == sending ? AppColors.brandBlueDark : Colors.transparent,
          foregroundColor: _sending == sending ? Colors.white : AppColors.textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          shape: const StadiumBorder(),
        ),
        child: Text(label, textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    ),
  );

  Widget _address(String label, String address, bool pickup, VoidCallback tap) {
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(width: 18, child: Column(children: [
          const SizedBox(height: 5),
          Container(width: 10, height: 10, decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: pickup ? AppColors.brandBlueDark : const Color(0xFFBCC9F5),
          )),
          if (pickup) Expanded(child: Container(width: 1.5,
            margin: const EdgeInsets.only(top: 5), color: AppColors.brandBlueDark)),
        ])),
        const SizedBox(width: 8),
        Expanded(child: Padding(
          padding: EdgeInsets.only(bottom: pickup ? 26 : 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: _sf(size: 14)),
            const SizedBox(height: 12),
            Material(color: const Color(0xFFF3F3F3), borderRadius: BorderRadius.circular(7),
              child: InkWell(onTap: controller.isCalculatingRoute ? null : tap,
                borderRadius: BorderRadius.circular(7),
                child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                  child: Row(children: [
                    Icon(pickup ? Icons.location_on_outlined : Icons.search,
                      size: 21, color: AppColors.brandBlueDark),
                    const SizedBox(width: 9),
                    Expanded(child: Text(address, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: _sf(size: 13, height: 1.4))),
                  ])),
              )),
          ]),
        )),
      ]),
    );
  }

  InputDecoration _input(String label, String hint) => InputDecoration(
    labelText: label, hintText: hint, filled: true, fillColor: const Color(0xFFF3F3F3),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.brandBlueDark)),
    contentPadding: const EdgeInsets.all(16),
  );

  @override
  Widget build(BuildContext context) {
    ref.watch(locationNotifierProvider);
    return AnimatedBuilder(animation: controller, builder: (context, _) {
      final busy = _loadingProfile || _reviewing || controller.isCalculatingRoute;
      final amount = controller.totalAmount;
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarContrastEnforced: false,
        ),
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
          backgroundColor: Colors.white, surfaceTintColor: Colors.white, elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () {
            if (_step > 0) { setState(() => _step = 0); }
            else { Navigator.maybePop(context); }
          }),
          title: Text('Send & receive', style: _sf(size: 19, weight: FontWeight.w700)),
        ),
        body: SafeArea(child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(children: [
            Padding(padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
              child: Container(padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: const Color(0xFFF0F3FC), borderRadius: BorderRadius.circular(40)),
                child: Row(children: [_tab('Send a package', true), _tab('Receive a package', false)]))),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            Expanded(child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
              child: _step == 0 ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Delivery details', style: _sf(size: 18, weight: FontWeight.w700)),
                const SizedBox(height: 24),
                _address('Pick up', _displayAddress(controller.pickupLocation, 'Choose pickup address'), true, _openPickupAddressScreen),
                _address('Drop off', _displayAddress(controller.dropoffLocation, 'Choose drop-off address'), false, _openDeliveryAddressScreen),
                if (controller.locationError != null) ...[
                  const SizedBox(height: 16),
                  Text(controller.locationError!, style: _sf(size: 12, color: AppColors.error)),
                  TextButton(onPressed: busy ? null : () => controller.fetchEstimate(), child: const Text('Retry estimate')),
                ],
                if (_profileError != null) ...[
                  const SizedBox(height: 16), Text(_profileError!, style: _sf(size: 12, color: AppColors.error)),
                  TextButton(onPressed: busy ? null : _loadProfile, child: const Text('Reload account details')),
                ],
              ]) : Form(key: _form, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_sending ? 'Who’s receiving?' : 'Who’s sending?', style: _sf(size: 22, weight: FontWeight.w700)),
                const SizedBox(height: 10),
                Text(_sending ? 'We’ll use your account details for pickup.' : 'We’ll use your account details for drop-off.',
                  style: _sf(size: 13, color: AppColors.textSecondary, height: 1.5)),
                const SizedBox(height: 24),
                TextFormField(controller: _name, textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: _input(_sending ? 'Receiver’s name' : 'Sender’s name', 'Full name'),
                  validator: (value) => (value ?? '').trim().isEmpty ? 'Enter their name' : null),
                const SizedBox(height: 16),
                TextFormField(controller: _phone, keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  decoration: _input('Phone number', '08012345678'),
                  validator: (value) => _normalizedPhone(value ?? '') == null ? 'Enter a valid phone number' : null),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(value: _packageType,
                  decoration: _input('Package type', ''),
                  items: const ['Parcel', 'Box', 'Food', 'Documents', 'Medicine', 'Perishable', 'Other']
                    .map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                  onChanged: (value) { if (value != null) setState(() => _packageType = value); }),
              ])),
            )),
            Padding(padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
              child: SizedBox(width: double.infinity,
                child: ElevatedButton(onPressed: busy ? null : _next,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandBlueDark,
                    foregroundColor: Colors.white, disabledBackgroundColor: AppColors.brandBlueDark.withOpacity(.55),
                    disabledForegroundColor: Colors.white, elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: Row(children: [
                    Expanded(child: Text(busy ? 'Please wait…' : _step == 0 ? 'Continue' : 'Review delivery',
                      style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600))),
                    if (controller.isCalculatingRoute) const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    else if (amount != null) Text('₦${_formatAmount(amount)}',
                      style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w600)),
                  ])),
              )),
          ]),
        ))),
        ),
      );
    });
  }
}