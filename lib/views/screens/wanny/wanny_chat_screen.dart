import 'dart:ui';

import 'package:flutter/material.dart';
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
import 'package:wanmac/services/wanny_service.dart';
import 'package:wanmac/views/screens/ReviewPaymentScreen/review_payment_screen.dart';
import 'package:wanmac/views/screens/map/map_location_picker_scren.dart';
import 'package:wanmac/views/screens/send_package/address_search_screen.dart';

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

double _r(BuildContext context, double value) => value * _scale(context);

class WannyChatScreen extends ConsumerStatefulWidget {
  final String userId;
  final String? userName;

  const WannyChatScreen({super.key, required this.userId, this.userName});

  @override
  ConsumerState<WannyChatScreen> createState() => _WannyChatScreenState();
}

class _WannyChatScreenState extends ConsumerState<WannyChatScreen> {
  final WannyChatService _chatService = WannyChatService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_ChatMessage> _messages = [];
  List<WannySuggestion> _suggestions = [];

  late SendPackageController _orderController;

  bool _isLoading = false;
  bool _isOrderFlowBusy = false;

  @override
  void initState() {
    super.initState();

    _orderController = SendPackageController(
      LocationService(),
      const LocationRequestApiService(baseUrl: ApiConfig.ordersBaseUrl),
      const OrderEstimateApiService(estimateUrl: ApiConfig.estimateUrl),
      const OrderApiService(),
    );

    _orderController.setCurrentUserId(widget.userId);

    if ((widget.userName ?? '').trim().isNotEmpty) {
      _orderController.setSenderName(widget.userName!.trim());
    }

    _loadSenderDetails();
    _startChat();
  }

  Future<void> _startChat() async {
    await _sendToBot(message: 'start');
  }

  Future<void> _loadSenderDetails() async {
    final prefs = await SharedPreferences.getInstance();

    final firstName = prefs.getString('firstName') ?? '';
    final lastName = prefs.getString('lastName') ?? '';
    final email = prefs.getString('email') ?? '';
    final phoneNumber = prefs.getString('phoneNumber') ?? '';
    final savedUserId = prefs.getString('userId') ?? widget.userId;

    final fullName = '$firstName $lastName'.trim();
    final countryCode = _extractCountryCode(phoneNumber);
    final localPhone = _extractLocalPhone(phoneNumber);

    if (!mounted) return;

    if (fullName.isNotEmpty) {
      _orderController.setSenderName(fullName);
    }

    if (email.isNotEmpty) {
      _orderController.setSenderEmail(email);
    }

    if (localPhone.isNotEmpty) {
      _orderController.setSenderPhone(localPhone);
    }

    _orderController.setSenderCode(countryCode);
    _orderController.setCurrentUserId(savedUserId);
  }

  String _extractCountryCode(String phone) {
    final trimmed = phone.trim();

    if (trimmed.startsWith('+234')) return '+234';
    if (trimmed.startsWith('+')) {
      final match = RegExp(r'^(\+\d{1,4})').firstMatch(trimmed);
      return match?.group(1) ?? '+234';
    }

    return '+234';
  }

  String _extractLocalPhone(String phone) {
    final trimmed = phone.trim();

    if (trimmed.startsWith('+234')) {
      return '0${trimmed.substring(4)}';
    }

    return trimmed;
  }

  Future<void> _sendUserMessage(String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty || _isLoading || _isOrderFlowBusy) return;

    _controller.clear();

    setState(() {
      _messages.add(_ChatMessage(text: trimmed, isUser: true));
      _suggestions = [];
    });

    await _sendToBot(message: trimmed);
  }

  Future<void> _sendToBot({required String message}) async {
    setState(() => _isLoading = true);
    _scrollToBottom();

    try {
      final result = await _chatService.sendMessage(
        message: message,
        sessionId: widget.userId,
        name: widget.userName,
      );

      setState(() {
        _messages.add(_ChatMessage(text: result.message, isUser: false));
        _suggestions = result.suggestions;
      });

      await _handleBotAction(result);
    } catch (_) {
      setState(() {
        _messages.add(
          const _ChatMessage(
            text:
                'Sorry, Wanny is having trouble responding right now. Please try again.',
            isUser: false,
          ),
        );
      });
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  Future<void> _handleBotAction(WannyChatResponse result) async {
    if (!mounted) return;

    switch (result.action) {
      case 'open_pickup_location_picker':
        await _openPickupFlow(nextAction: result.nextAction);
        break;

      case 'open_delivery_location_picker':
        _addBotActionMessage(
          'Choose where the package should be delivered.',
          actions: [
            _ChatAction(label: 'Choose delivery', onTap: _openDeliveryFlow),
          ],
        );
        _removeDuplicateLocationMessages(isPickup: false);
        break;

      case 'open_receiver_details_form':
        _addBotActionMessage(
          'Now add the receiver details.',
          actions: [
            _ChatAction(
              label: 'Add receiver details',
              onTap: _openReceiverDetailsSheet,
            ),
          ],
        );
        break;

      case 'open_package_details_form':
        _addBotActionMessage(
          'Now tell me what type of package you are sending.',
          actions: [
            _ChatAction(
              label: 'Add package details',
              onTap: _openPackageDetailsSheet,
            ),
          ],
        );
        break;

      case 'show_order_review':
        _addBotActionMessage(
          'Everything is ready. Review your delivery before confirming.',
          actions: [
            _ChatAction(label: 'Review delivery', onTap: _openReviewScreen),
          ],
        );
        break;

      default:
        break;
    }
  }

  Future<void> _openPickupFlow({String? nextAction}) async {
    if (_isOrderFlowBusy) return;

    setState(() => _isOrderFlowBusy = true);

    LocationModel? selected;
    final notifier = ref.read(locationNotifierProvider.notifier);
    var locationState = ref.read(locationNotifierProvider);

    selected = locationState.pickupLocation ?? locationState.currentLocation;

    if (selected == null) {
      await notifier.fetchCurrentLocation();

      if (!mounted) return;

      locationState = ref.read(locationNotifierProvider);
      selected = locationState.pickupLocation ?? locationState.currentLocation;
    }

    if (!mounted) return;
    setState(() => _isOrderFlowBusy = false);

    if (selected == null) {
      _addBotActionMessage(
        'I could not detect your pickup automatically. Choose the pickup location manually.',
        actions: [
          _ChatAction(
            label: 'Choose pickup',
            onTap: () => _openPickupPickerManually(nextAction: nextAction),
          ),
        ],
      );
      _removeDuplicateLocationMessages(isPickup: true);
      return;
    }

    ref.read(locationNotifierProvider.notifier).setPickupLocation(selected);
    _orderController.setPickupLocation(selected, addToRecent: true);

    _addBotActionMessage(
      'Pickup selected\n${_formatLocation(selected)}',
      actions: [
        _ChatAction(
          label: 'Change',
          onTap: () => _openPickupPickerManually(
            nextAction: 'open_delivery_location_picker',
          ),
        ),
        _ChatAction(label: 'Continue', onTap: _openDeliveryFlow),
      ],
    );

    _removeDuplicateLocationMessages(isPickup: true);
  }

  Future<void> _openPickupPickerManually({String? nextAction}) async {
    if (_isOrderFlowBusy) return;

    setState(() => _isOrderFlowBusy = true);

    final selected = await _showLocationOptionsSheet(
      title: 'Choose pickup location',
      subtitle: 'Search an address or choose the exact pickup point on map.',
      isPickup: true,
    );

    if (!mounted) return;

    setState(() => _isOrderFlowBusy = false);

    if (selected == null) return;

    ref.read(locationNotifierProvider.notifier).setPickupLocation(selected);
    _orderController.setPickupLocation(selected, addToRecent: true);

    _addBotActionMessage(
      'Pickup updated\n${_formatLocation(selected)}',
      actions: [
        _ChatAction(
          label: 'Change',
          onTap: () => _openPickupPickerManually(
            nextAction: 'open_delivery_location_picker',
          ),
        ),
        _ChatAction(label: 'Continue', onTap: _openDeliveryFlow),
      ],
    );

    _removeDuplicateLocationMessages(isPickup: true);
  }

  Future<void> _openDeliveryFlow() async {
    if (_isOrderFlowBusy) return;

    setState(() => _isOrderFlowBusy = true);

    final selected = await _showLocationOptionsSheet(
      title: 'Choose delivery location',
      subtitle: 'Search with Google Places or choose the exact point on map.',
      isPickup: false,
    );

    if (!mounted) return;

    setState(() => _isOrderFlowBusy = false);

    if (selected == null) return;

    ref.read(locationNotifierProvider.notifier).setDropoffLocation(selected);
    _orderController.setDropoffLocation(selected, addToRecent: true);

    _addBotActionMessage(
      'Delivery selected\n${_formatLocation(selected)}',
      actions: [
        _ChatAction(label: 'Change', onTap: _openDeliveryFlow),
        _ChatAction(
          label: 'Continue',
          onTap: _calculateEstimateThenAskReceiver,
        ),
      ],
    );

    _removeDuplicateLocationMessages(isPickup: false);
  }

  Future<LocationModel?> _showLocationOptionsSheet({
    required String title,
    required String subtitle,
    required bool isPickup,
  }) async {
    return showModalBottomSheet<LocationModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: Colors.black.withOpacity(0.06),
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _LocationChoiceSheet(
          title: title,
          subtitle: subtitle,
          isPickup: isPickup,
          onSearchAddress: () => _openAddressSearch(isPickup: isPickup),
          onChooseOnMap: () => _openMapPicker(isPickup: isPickup),
        );
      },
    );
  }

  Future<LocationModel?> _openAddressSearch({required bool isPickup}) async {
    return Navigator.push<LocationModel>(
      context,
      MaterialPageRoute(
        builder: (_) => AddressSearchScreen(
          title: isPickup ? 'Pickup address' : 'Delivery address',
          controller: _orderController,
          isPickup: isPickup,
        ),
      ),
    );
  }

  Future<LocationModel?> _openMapPicker({required bool isPickup}) async {
    final locationState = ref.read(locationNotifierProvider);

    final initialLocation = isPickup
        ? (locationState.pickupLocation ?? locationState.currentLocation)
        : locationState.dropoffLocation;

    return Navigator.push<LocationModel>(
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
  }

  Future<void> _calculateEstimateThenAskReceiver() async {
    if (_orderController.pickupLocation == null ||
        _orderController.dropoffLocation == null) {
      _addBotMessage('Please select both pickup and delivery locations first.');
      return;
    }

    try {
      await _orderController.fetchEstimate();

      if (!mounted) return;

      final amount = _orderController.totalAmount == null
          ? 'the delivery fee'
          : '₦${_orderController.totalAmount!.toStringAsFixed(0)}';

      final eta = _orderController.routeDuration ?? 'a few minutes';

      _addBotActionMessage(
        'Your estimated delivery fee is $amount. Estimated delivery time is $eta. Now add the receiver details.',
        actions: [
          _ChatAction(
            label: 'Add receiver details',
            onTap: _openReceiverDetailsSheet,
          ),
        ],
      );
    } catch (_) {
      if (!mounted) return;

      _addBotMessage(
        'I could not calculate the delivery fee right now. Please check the selected locations and try again.',
      );
    }
  }

  Future<void> _openReceiverDetailsSheet() async {
    if (_isOrderFlowBusy) return;

    setState(() => _isOrderFlowBusy = true);

    final result = await showModalBottomSheet<_ReceiverDetailsResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: Colors.black.withOpacity(0.06),
      backgroundColor: Colors.transparent,
      builder: (_) => const _ReceiverDetailsSheet(),
    );

    if (!mounted) return;

    setState(() => _isOrderFlowBusy = false);

    if (result == null) return;

    _orderController.setReceiverName(result.name);
    _orderController.setReceiverCode(result.code);
    _orderController.setReceiverPhone(result.phone);

    _addBotActionMessage(
      'Receiver details added. What type of package are you sending?',
      actions: [
        _ChatAction(
          label: 'Add package details',
          onTap: _openPackageDetailsSheet,
        ),
      ],
    );
  }

  Future<void> _openPackageDetailsSheet() async {
    if (_isOrderFlowBusy) return;

    setState(() => _isOrderFlowBusy = true);

    final result = await showModalBottomSheet<_PackageDetailsResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: Colors.black.withOpacity(0.06),
      backgroundColor: Colors.transparent,
      builder: (_) => const _PackageDetailsSheet(),
    );

    if (!mounted) return;

    setState(() => _isOrderFlowBusy = false);

    if (result == null) return;

    _orderController.setPackageType(result.packageType);
    _orderController.setPackageDescription(result.description);
    _orderController.setApplyProtection(result.applyProtection);
    _orderController.setPackageFragile(result.applyProtection);

    _addBotActionMessage(
      'Package details added. You can now review and confirm your delivery.',
      actions: [
        _ChatAction(label: 'Review delivery', onTap: _openReviewScreen),
      ],
    );
  }

  Future<void> _openReviewScreen() async {
    if (_orderController.pickupLocation == null ||
        _orderController.dropoffLocation == null) {
      _addBotMessage(
        'Please select pickup and delivery locations before review.',
      );
      return;
    }

    if (_orderController.senderPhone.trim().isEmpty) {
      _addBotMessage(
        'Your sender phone number is missing. Please update your account details and try again.',
      );
      return;
    }

    if (_orderController.receiverName.trim().isEmpty ||
        _orderController.receiverPhone.trim().isEmpty) {
      _addBotMessage(
        'Please add receiver name and phone number before review.',
      );
      return;
    }

    if ((_orderController.selectedPackageType ?? '').trim().isEmpty) {
      _addBotMessage('Please select the package type before review.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewPaymentScreen(controller: _orderController),
      ),
    );
  }

  String _formatLocation(LocationModel location) {
    final name = location.name?.trim() ?? '';
    final address = location.address.trim();
    final shortAddress = location.shortAddress?.trim() ?? '';

    if (address.isNotEmpty) return address;
    if (name.isNotEmpty && shortAddress.isNotEmpty) {
      return '$name, $shortAddress';
    }
    if (name.isNotEmpty) return name;
    if (shortAddress.isNotEmpty) return shortAddress;

    return 'Selected location';
  }

  void _addBotMessage(String text) {
    if (!mounted) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: false));
      _suggestions = [];
    });

    _scrollToBottom();
  }

  void _addBotActionMessage(String text, {required List<_ChatAction> actions}) {
    if (!mounted) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: false, actions: actions));
      _suggestions = [];
    });

    _scrollToBottom();
  }

  void _removeDuplicateLocationMessages({required bool isPickup}) {
    if (!mounted) return;

    setState(() {
      final keyword = isPickup ? 'pickup' : 'delivery';
      final indexes = <int>[];

      for (int i = 0; i < _messages.length; i++) {
        final message = _messages[i];
        if (message.isUser) continue;

        final lowerText = message.text.toLowerCase();

        if (lowerText.contains(keyword) &&
            (lowerText.contains('selected') ||
                lowerText.contains('updated') ||
                lowerText.contains('choose'))) {
          indexes.add(i);
        }
      }

      if (indexes.length <= 1) return;

      for (int i = indexes.length - 2; i >= 0; i--) {
        _messages.removeAt(indexes[i]);
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  TextStyle _font({
    required BuildContext context,
    required double size,
    required FontWeight weight,
    required Color color,
    double? height,
  }) {
    return GoogleFonts.montserrat(
      fontSize: _r(context, size),
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    final inputEnabled = !_isLoading && !_isOrderFlowBusy;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _PremiumChatHeader(),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: _maxContentWidth(context),
                  ),
                  child: Container(
                    margin: EdgeInsets.fromLTRB(
                      _r(context, 12),
                      _r(context, 8),
                      _r(context, 12),
                      0,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(_r(context, 30)),
                      ),
                      border: Border.all(color: const Color(0xFFE8EAF2)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF101828).withOpacity(0.06),
                          blurRadius: _r(context, 28),
                          offset: Offset(0, _r(context, 14)),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        const Positioned.fill(child: _ChatBackground()),
                        Column(
                          children: [
                            Expanded(
                              child: _messages.isEmpty && _isLoading
                                  ? Center(
                                      child: Text(
                                        'Connecting to Wanny...',
                                        style: _font(
                                          context: context,
                                          size: 13,
                                          weight: FontWeight.w600,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      controller: _scrollController,
                                      padding: EdgeInsets.fromLTRB(
                                        _r(context, 16),
                                        _r(context, 22),
                                        _r(context, 16),
                                        _r(context, 12),
                                      ),
                                      itemCount:
                                          _messages.length +
                                          (_isLoading ? 1 : 0),
                                      itemBuilder: (context, index) {
                                        if (_isLoading &&
                                            index == _messages.length) {
                                          return const _TypingBubble();
                                        }

                                        return _MessageBubble(
                                          message: _messages[index],
                                          isBusy: _isOrderFlowBusy,
                                        );
                                      },
                                    ),
                            ),
                            if (_suggestions.isNotEmpty)
                              _SuggestionsBar(
                                suggestions: _suggestions,
                                onTap: (suggestion) =>
                                    _sendUserMessage(suggestion.payload),
                              ),
                            _ChatInput(
                              controller: _controller,
                              enabled: inputEnabled,
                              onSend: _sendUserMessage,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumChatHeader extends StatelessWidget {
  const _PremiumChatHeader();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: _maxContentWidth(context)),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            _r(context, 16),
            _r(context, 12),
            _r(context, 16),
            _r(context, 8),
          ),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: _r(context, 12),
              vertical: _r(context, 12),
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(_r(context, 24)),
              border: Border.all(color: const Color(0xFFE8EAF2)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF101828).withOpacity(0.045),
                  blurRadius: _r(context, 20),
                  offset: Offset(0, _r(context, 8)),
                ),
              ],
            ),
            child: Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(_r(context, 16)),
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: _r(context, 42),
                    height: _r(context, 42),
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(_r(context, 16)),
                      border: Border.all(color: AppColors.inputBorder),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textPrimary,
                      size: _r(context, 17),
                    ),
                  ),
                ),
                SizedBox(width: _r(context, 12)),
                Container(
                  width: _r(context, 46),
                  height: _r(context, 46),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.brandBlue, AppColors.brandBlueDark],
                    ),
                    borderRadius: BorderRadius.circular(_r(context, 18)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brandBlue.withOpacity(0.22),
                        blurRadius: _r(context, 18),
                        offset: Offset(0, _r(context, 8)),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'W',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: _r(context, 22),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: _r(context, 12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wanny',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          color: AppColors.textPrimary,
                          fontSize: _r(context, 18),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: _r(context, 3)),
                      Text(
                        'WANPADI assistant',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          color: AppColors.textSecondary,
                          fontSize: _r(context, 12.2),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: _r(context, 10),
                    vertical: _r(context, 7),
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF3),
                    borderRadius: BorderRadius.circular(_r(context, 999)),
                    border: Border.all(color: const Color(0xFFD1FADF)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.circle,
                        size: _r(context, 8),
                        color: const Color(0xFF12B76A),
                      ),
                      SizedBox(width: _r(context, 6)),
                      Text(
                        'Online',
                        style: GoogleFonts.montserrat(
                          color: const Color(0xFF027A48),
                          fontSize: _r(context, 11),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatBackground extends StatelessWidget {
  const _ChatBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: CustomPaint(painter: _ChatBackgroundPainter()),
        ),
        Positioned(
          top: _r(context, 48),
          right: -_r(context, 26),
          child: Opacity(
            opacity: 0.045,
            child: Image.asset(
              'assets/images/wanmac_bike.png',
              width: _r(context, 112),
              fit: BoxFit.contain,
            ),
          ),
        ),
        Positioned(
          top: _r(context, 290),
          left: -_r(context, 36),
          child: Opacity(
            opacity: 0.035,
            child: Image.asset(
              'assets/images/wanmac_bike.png',
              width: _r(context, 106),
              fit: BoxFit.contain,
            ),
          ),
        ),
        Positioned(
          bottom: _r(context, 92),
          right: -_r(context, 42),
          child: Opacity(
            opacity: 0.035,
            child: Image.asset(
              'assets/images/wanmac_bike.png',
              width: _r(context, 110),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  final bool isBusy;

  const _MessageBubble({required this.message, required this.isBusy});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final hasActions = !isUser && message.actions.isNotEmpty;
    final contentMaxWidth = _maxContentWidth(context);
    final availableWidth = contentMaxWidth == double.infinity
        ? MediaQuery.sizeOf(context).width
        : contentMaxWidth;
    final maxWidth = hasActions ? availableWidth * 0.82 : availableWidth * 0.76;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        margin: EdgeInsets.only(bottom: _r(context, 13)),
        padding: EdgeInsets.symmetric(
          horizontal: _r(context, 15),
          vertical: _r(context, 12),
        ),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.brandBlue, AppColors.brandBlueDark],
                )
              : null,
          color: isUser ? null : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(_r(context, 20)),
            topRight: Radius.circular(_r(context, 20)),
            bottomLeft: Radius.circular(
              isUser ? _r(context, 20) : _r(context, 8),
            ),
            bottomRight: Radius.circular(
              isUser ? _r(context, 8) : _r(context, 20),
            ),
          ),
          border: isUser
              ? null
              : Border.all(color: const Color(0xFFE8EAF2), width: 1),
          boxShadow: [
            BoxShadow(
              color: isUser
                  ? AppColors.brandBlue.withOpacity(0.18)
                  : const Color(0xFF101828).withOpacity(0.055),
              blurRadius: isUser ? _r(context, 18) : _r(context, 16),
              offset: Offset(0, _r(context, 8)),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.text,
              style: GoogleFonts.montserrat(
                color: isUser ? Colors.white : AppColors.textPrimary,
                fontSize: _r(context, 14.2),
                height: 1.42,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (hasActions) ...[
              SizedBox(height: _r(context, 12)),
              Wrap(
                spacing: _r(context, 8),
                runSpacing: _r(context, 8),
                children: message.actions.map((action) {
                  return SizedBox(
                    height: _r(context, 42),
                    child: ElevatedButton(
                      onPressed: isBusy ? null : action.onTap,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: AppColors.brandBlueDark,
                        disabledBackgroundColor: AppColors.textHint,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: _r(context, 14),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_r(context, 14)),
                        ),
                      ),
                      child: Text(
                        action.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: _r(context, 12.2),
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SuggestionsBar extends StatelessWidget {
  final List<WannySuggestion> suggestions;
  final ValueChanged<WannySuggestion> onTap;

  const _SuggestionsBar({required this.suggestions, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        _r(context, 14),
        _r(context, 6),
        _r(context, 14),
        _r(context, 10),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: suggestions.map((suggestion) {
            return Padding(
              padding: EdgeInsets.only(right: _r(context, 8)),
              child: InkWell(
                borderRadius: BorderRadius.circular(_r(context, 999)),
                onTap: () => onTap(suggestion),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: _r(context, 14),
                    vertical: _r(context, 10),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.infoBg,
                    borderRadius: BorderRadius.circular(_r(context, 999)),
                    border: Border.all(
                      color: AppColors.brandBlue.withOpacity(0.12),
                    ),
                  ),
                  child: Text(
                    suggestion.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      color: AppColors.brandBlue,
                      fontWeight: FontWeight.w800,
                      fontSize: _r(context, 12.8),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onSend;

  const _ChatInput({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        _r(context, 14),
        _r(context, 12),
        _r(context, 14),
        _r(context, 12) + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: Color(0xFFE8EAF2), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              minLines: 1,
              maxLines: 4,
              style: GoogleFonts.montserrat(
                fontSize: _r(context, 14),
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: enabled ? onSend : null,
              decoration: InputDecoration(
                hintText: 'Message Wanny...',
                hintStyle: GoogleFonts.montserrat(
                  color: AppColors.textHint,
                  fontSize: _r(context, 13.5),
                  fontWeight: FontWeight.w500,
                ),
                filled: true,
                fillColor: AppColors.inputFill,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: _r(context, 17),
                  vertical: _r(context, 15),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(_r(context, 20)),
                  borderSide: const BorderSide(
                    color: AppColors.inputBorder,
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(_r(context, 20)),
                  borderSide: const BorderSide(
                    color: AppColors.inputBorder,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(_r(context, 20)),
                  borderSide: BorderSide(
                    color: AppColors.brandBlue.withOpacity(0.85),
                    width: 1.3,
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(_r(context, 20)),
                  borderSide: const BorderSide(
                    color: AppColors.inputBorder,
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: _r(context, 10)),
          InkWell(
            onTap: enabled ? () => onSend(controller.text) : null,
            borderRadius: BorderRadius.circular(_r(context, 18)),
            child: Container(
              width: _r(context, 50),
              height: _r(context, 50),
              decoration: BoxDecoration(
                gradient: enabled
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.brandBlue, AppColors.brandBlueDark],
                      )
                    : null,
                color: enabled ? null : AppColors.textHint,
                borderRadius: BorderRadius.circular(_r(context, 18)),
                boxShadow: enabled
                    ? [
                        BoxShadow(
                          color: AppColors.brandBlue.withOpacity(0.22),
                          blurRadius: _r(context, 16),
                          offset: Offset(0, _r(context, 7)),
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                Icons.arrow_upward_rounded,
                color: Colors.white,
                size: _r(context, 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: _r(context, 13)),
        padding: EdgeInsets.symmetric(
          horizontal: _r(context, 15),
          vertical: _r(context, 12),
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(_r(context, 20)),
          border: Border.all(color: const Color(0xFFE8EAF2)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF101828).withOpacity(0.045),
              blurRadius: _r(context, 14),
              offset: Offset(0, _r(context, 7)),
            ),
          ],
        ),
        child: Text(
          'Wanny is typing...',
          style: GoogleFonts.montserrat(
            color: AppColors.textSecondary,
            fontSize: _r(context, 13),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _LocationChoiceSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isPickup;
  final Future<LocationModel?> Function() onSearchAddress;
  final Future<LocationModel?> Function() onChooseOnMap;

  const _LocationChoiceSheet({
    required this.title,
    required this.subtitle,
    required this.isPickup,
    required this.onSearchAddress,
    required this.onChooseOnMap,
  });

  @override
  Widget build(BuildContext context) {
    return _PremiumSheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SheetHandle(),
          SizedBox(height: _r(context, 18)),
          _SheetHeader(
            icon: isPickup
                ? Icons.my_location_rounded
                : Icons.location_on_rounded,
            title: title,
            subtitle: subtitle,
          ),
          SizedBox(height: _r(context, 20)),
          _SheetActionTile(
            icon: Icons.search_rounded,
            title: isPickup
                ? 'Search pickup address'
                : 'Search delivery address',
            subtitle: 'Use Google Places to select the exact address',
            onTap: () async {
              final result = await onSearchAddress();
              if (context.mounted) Navigator.pop(context, result);
            },
          ),
          SizedBox(height: _r(context, 12)),
          _SheetActionTile(
            icon: Icons.map_outlined,
            title: 'Choose on map',
            subtitle: 'Pin the exact location manually',
            onTap: () async {
              final result = await onChooseOnMap();
              if (context.mounted) Navigator.pop(context, result);
            },
          ),
          SizedBox(height: _r(context, 4)),
        ],
      ),
    );
  }
}

class _ReceiverDetailsSheet extends StatefulWidget {
  const _ReceiverDetailsSheet();

  @override
  State<_ReceiverDetailsSheet> createState() => _ReceiverDetailsSheetState();
}

class _ReceiverDetailsSheetState extends State<_ReceiverDetailsSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String _code = '+234';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      AppSnackBar.show(
        context,
        message: 'Please enter receiver name and phone number',
        type: AppSnackBarType.warning,
      );
      return;
    }

    Navigator.pop(
      context,
      _ReceiverDetailsResult(name: name, code: _code, phone: phone),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _PremiumSheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SheetHandle(),
          SizedBox(height: _r(context, 18)),
          const _SheetHeader(
            icon: Icons.person_outline_rounded,
            title: 'Receiver details',
            subtitle:
                'Add the name and phone number of the person receiving the package.',
          ),
          SizedBox(height: _r(context, 18)),
          _SheetTextField(
            controller: _nameController,
            hintText: 'Receiver name',
            icon: Icons.person_outline_rounded,
            textInputType: TextInputType.name,
          ),
          SizedBox(height: _r(context, 12)),
          Row(
            children: [
              Container(
                height: _r(context, 56),
                padding: EdgeInsets.symmetric(horizontal: _r(context, 14)),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(_r(context, 16)),
                  border: Border.all(color: AppColors.inputBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _code,
                    borderRadius: BorderRadius.circular(_r(context, 16)),
                    items: const [
                      DropdownMenuItem(value: '+234', child: Text('+234')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _code = value);
                    },
                  ),
                ),
              ),
              SizedBox(width: _r(context, 10)),
              Expanded(
                child: _SheetTextField(
                  controller: _phoneController,
                  hintText: 'Phone number',
                  icon: Icons.phone_outlined,
                  textInputType: TextInputType.phone,
                ),
              ),
            ],
          ),
          SizedBox(height: _r(context, 20)),
          _PrimarySheetButton(label: 'Continue', onTap: _submit),
        ],
      ),
    );
  }
}

class _PackageDetailsSheet extends StatefulWidget {
  const _PackageDetailsSheet();

  @override
  State<_PackageDetailsSheet> createState() => _PackageDetailsSheetState();
}

class _PackageDetailsSheetState extends State<_PackageDetailsSheet> {
  final TextEditingController _descriptionController = TextEditingController();

  String? _selectedPackageType;
  bool _applyProtection = false;

  final List<String> _packageTypes = const [
    'Box',
    'Parcel',
    'Perishable',
    'Food',
    'Documents',
    'Medicine',
    'Other',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if ((_selectedPackageType ?? '').trim().isEmpty) {
      AppSnackBar.show(
        context,
        message: 'Please select a package type',
        type: AppSnackBarType.warning,
      );
      return;
    }

    final description = _descriptionController.text.trim().isEmpty
        ? '${_selectedPackageType!} delivery'
        : _descriptionController.text.trim();

    Navigator.pop(
      context,
      _PackageDetailsResult(
        packageType: _selectedPackageType!,
        description: description,
        applyProtection: _applyProtection,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _PremiumSheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SheetHandle(),
          SizedBox(height: _r(context, 18)),
          const _SheetHeader(
            icon: Icons.inventory_2_outlined,
            title: 'Package details',
            subtitle: 'Tell Wanny what you are sending.',
          ),
          SizedBox(height: _r(context, 18)),
          Wrap(
            spacing: _r(context, 9),
            runSpacing: _r(context, 9),
            children: _packageTypes.map((type) {
              final selected = _selectedPackageType == type;

              return InkWell(
                borderRadius: BorderRadius.circular(_r(context, 999)),
                onTap: () => setState(() => _selectedPackageType = type),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: _r(context, 14),
                    vertical: _r(context, 11),
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.brandBlueDark
                        : AppColors.brandBlueDark.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(_r(context, 999)),
                    border: Border.all(
                      color: selected
                          ? AppColors.brandBlueDark
                          : AppColors.brandBlueDark.withOpacity(0.14),
                    ),
                  ),
                  child: Text(
                    type,
                    style: GoogleFonts.montserrat(
                      color: selected ? Colors.white : AppColors.brandBlueDark,
                      fontSize: _r(context, 12.5),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: _r(context, 16)),
          _SheetTextField(
            controller: _descriptionController,
            hintText: 'Description e.g. small food pack',
            icon: Icons.edit_note_rounded,
            textInputType: TextInputType.text,
          ),
          SizedBox(height: _r(context, 14)),
          InkWell(
            borderRadius: BorderRadius.circular(_r(context, 18)),
            onTap: () => setState(() => _applyProtection = !_applyProtection),
            child: Container(
              padding: EdgeInsets.all(_r(context, 14)),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(_r(context, 18)),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    _applyProtection
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: _applyProtection
                        ? AppColors.brandBlueDark
                        : AppColors.textSecondary,
                    size: _r(context, 22),
                  ),
                  SizedBox(width: _r(context, 10)),
                  Expanded(
                    child: Text(
                      'Mark as fragile / protected',
                      style: GoogleFonts.montserrat(
                        color: AppColors.textPrimary,
                        fontSize: _r(context, 13.5),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: _r(context, 20)),
          _PrimarySheetButton(label: 'Review delivery', onTap: _submit),
        ],
      ),
    );
  }
}

class _PremiumSheetShell extends StatelessWidget {
  final Widget child;

  const _PremiumSheetShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxSheetHeight = MediaQuery.sizeOf(context).height * 0.54;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: _maxContentWidth(context),
            maxHeight: maxSheetHeight,
          ),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              _r(context, 20),
              _r(context, 12),
              _r(context, 20),
              _r(context, 26),
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(_r(context, 30)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: _r(context, 28),
                  offset: Offset(0, -_r(context, 10)),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: _r(context, 42),
        height: _r(context, 5),
        decoration: BoxDecoration(
          color: AppColors.inputBorder,
          borderRadius: BorderRadius.circular(_r(context, 100)),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SheetHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: _r(context, 46),
          height: _r(context, 46),
          decoration: BoxDecoration(
            color: AppColors.brandBlueDark.withOpacity(0.08),
            borderRadius: BorderRadius.circular(_r(context, 16)),
          ),
          child: Icon(
            icon,
            color: AppColors.brandBlueDark,
            size: _r(context, 23),
          ),
        ),
        SizedBox(width: _r(context, 12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  color: AppColors.textPrimary,
                  fontSize: _r(context, 18),
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: _r(context, 4)),
              Text(
                subtitle,
                style: GoogleFonts.montserrat(
                  color: AppColors.textSecondary,
                  fontSize: _r(context, 12.4),
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SheetActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SheetActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(_r(context, 18)),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: _r(context, 14),
          vertical: _r(context, 15),
        ),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(_r(context, 18)),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          children: [
            Container(
              width: _r(context, 42),
              height: _r(context, 42),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(_r(context, 14)),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: Icon(
                icon,
                color: AppColors.brandBlueDark,
                size: _r(context, 21),
              ),
            ),
            SizedBox(width: _r(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      color: AppColors.textPrimary,
                      fontSize: _r(context, 14),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: _r(context, 4)),
                  Text(
                    subtitle,
                    style: GoogleFonts.montserrat(
                      color: AppColors.textSecondary,
                      fontSize: _r(context, 12),
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.textHint,
              size: _r(context, 15),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final TextInputType textInputType;

  const _SheetTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    required this.textInputType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _r(context, 56),
      padding: EdgeInsets.symmetric(horizontal: _r(context, 14)),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(_r(context, 16)),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: _r(context, 20)),
          SizedBox(width: _r(context, 10)),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: textInputType,
              cursorColor: AppColors.brandBlue,
              style: GoogleFonts.montserrat(
                fontSize: _r(context, 14),
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                border: InputBorder.none,
                hintStyle: GoogleFonts.montserrat(
                  fontSize: _r(context, 13.5),
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimarySheetButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PrimarySheetButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: _r(context, 56),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.brandBlueDark,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_r(context, 18)),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: _r(context, 15),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ChatBackgroundPainter extends CustomPainter {
  const _ChatBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.surface, AppColors.background, Color(0xFFFFFFFF)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    final glow1 = Paint()
      ..color = AppColors.brandBlue.withOpacity(0.055)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);

    final glow2 = Paint()
      ..color = AppColors.brandBlueDark.withOpacity(0.035)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 90);

    canvas.drawCircle(
      Offset(size.width * 0.92, size.height * 0.12),
      size.width * 0.42,
      glow1,
    );

    canvas.drawCircle(
      Offset(size.width * 0.02, size.height * 0.82),
      size.width * 0.50,
      glow2,
    );

    final routePaint = Paint()
      ..color = AppColors.brandBlue.withOpacity(0.055)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    final route1 = Path()
      ..moveTo(size.width * 0.08, size.height * 0.16)
      ..cubicTo(
        size.width * 0.30,
        size.height * 0.04,
        size.width * 0.42,
        size.height * 0.28,
        size.width * 0.64,
        size.height * 0.18,
      )
      ..cubicTo(
        size.width * 0.82,
        size.height * 0.10,
        size.width * 0.86,
        size.height * 0.34,
        size.width * 0.96,
        size.height * 0.28,
      );

    final route2 = Path()
      ..moveTo(size.width * -0.05, size.height * 0.55)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.44,
        size.width * 0.30,
        size.height * 0.66,
        size.width * 0.50,
        size.height * 0.55,
      )
      ..cubicTo(
        size.width * 0.70,
        size.height * 0.43,
        size.width * 0.82,
        size.height * 0.68,
        size.width * 1.05,
        size.height * 0.54,
      );

    canvas.drawPath(route1, routePaint);
    canvas.drawPath(route2, routePaint);

    final dotPaint = Paint()
      ..color = AppColors.brandBlue.withOpacity(0.10)
      ..style = PaintingStyle.fill;

    void drawRouteDot(double x, double y) {
      canvas.drawCircle(Offset(size.width * x, size.height * y), 3.8, dotPaint);
      canvas.drawCircle(
        Offset(size.width * x, size.height * y),
        8,
        Paint()
          ..color = AppColors.brandBlue.withOpacity(0.035)
          ..style = PaintingStyle.fill,
      );
    }

    drawRouteDot(0.08, 0.16);
    drawRouteDot(0.64, 0.18);
    drawRouteDot(0.50, 0.55);
    drawRouteDot(0.92, 0.54);

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    void drawIcon(IconData icon, Offset offset, double sizeValue) {
      textPainter.text = TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: sizeValue,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: AppColors.brandBlue.withOpacity(0.045),
        ),
      );

      textPainter.layout();
      textPainter.paint(canvas, offset);
    }

    drawIcon(
      Icons.two_wheeler_rounded,
      Offset(size.width * 0.08, size.height * 0.30),
      34,
    );
    drawIcon(
      Icons.delivery_dining_rounded,
      Offset(size.width * 0.75, size.height * 0.36),
      34,
    );
    drawIcon(
      Icons.inventory_2_outlined,
      Offset(size.width * 0.14, size.height * 0.68),
      32,
    );
    drawIcon(
      Icons.location_on_outlined,
      Offset(size.width * 0.70, size.height * 0.72),
      34,
    );
    drawIcon(
      Icons.chat_bubble_outline_rounded,
      Offset(size.width * 0.40, size.height * 0.52),
      30,
    );

    final grainPaint = Paint()
      ..color = AppColors.brandBlue.withOpacity(0.018)
      ..style = PaintingStyle.fill;

    for (double x = 18; x < size.width; x += 42) {
      for (double y = 22; y < size.height; y += 42) {
        canvas.drawCircle(Offset(x, y), 1.0, grainPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ReceiverDetailsResult {
  final String name;
  final String code;
  final String phone;

  const _ReceiverDetailsResult({
    required this.name,
    required this.code,
    required this.phone,
  });
}

class _PackageDetailsResult {
  final String packageType;
  final String description;
  final bool applyProtection;

  const _PackageDetailsResult({
    required this.packageType,
    required this.description,
    required this.applyProtection,
  });
}

class _ChatAction {
  final String label;
  final Future<void> Function() onTap;

  const _ChatAction({required this.label, required this.onTap});
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final List<_ChatAction> actions;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.actions = const [],
  });
}
