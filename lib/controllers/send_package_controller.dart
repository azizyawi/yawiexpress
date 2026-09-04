import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wanmac/models/location_model.dart';
import 'package:wanmac/models/location_suggestion_model.dart';
import 'package:wanmac/models/order_estimate_model.dart';
import 'package:wanmac/services/location_request_api_service.dart';
import 'package:wanmac/services/location_service.dart';
import 'package:wanmac/services/order_api_service.dart';
import 'package:wanmac/services/order_estimate_api_service.dart';

class SendPackageController extends ChangeNotifier {
  bool _disposed = false;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  String _formatLocationAddress(LocationModel location) {
    final name = location.name?.trim() ?? '';

    if (name.isNotEmpty) {
      return '$name, ${location.address}';
    }

    return location.address;
  }
  final LocationService _locationService;
  final LocationRequestApiService _locationRequestApiService;
  final OrderEstimateApiService _orderEstimateApiService;
  final OrderApiService _orderApiService;

  void resetExceptPickup(LocationModel? pickup) {
    pickupLocation = pickup;
    pickupAddress = pickup?.address;

    dropoffLocation = null;
    dropoffAddress = null;

    receiverName = '';
    receiverPhone = '';
    receiverEmail = '';

    selectedPackageType = null;
    packageDescription = 'Package delivery';
    packageWeightKg = 1;
    packageQuantity = 1;
    packageIsFragile = false;
    applyProtection = false;

    deliveryFee = null;
    serviceFee = null;
    totalAmount = null;
    routeDuration = null;
    distanceKm = null;
    estimatedTimeMin = null;
    currency = null;
    routePolyline = null;

    paymentError = null;
    createdOrderId = null;

    clearPromo(notify: false);
    notifyListeners();
  }

  SendPackageController(
    this._locationService,
    this._locationRequestApiService,
    this._orderEstimateApiService,
    this._orderApiService,
  );

  bool isGettingCurrentLocation = false;
  bool isSearchingAddresses = false;

  // Address-search UI state.
  // This lets the address screen distinguish a real "no results" response
  // from a temporary network failure.
  bool hasAddressNetworkError = false;

  bool isCalculatingRoute = false;
  bool isCreatingPickupRequest = false;
  bool isCreatingDropoffRequest = false;
  bool isRefreshingPickupRequest = false;
  bool isRefreshingDropoffRequest = false;

  bool isCreatingOrder = false;
  bool isInitializingPayment = false;
  bool isVerifyingPayment = false;
  bool isPaying = false;

  String? pickupAddress;
  LocationModel? pickupLocation;

  String? dropoffAddress;
  LocationModel? dropoffLocation;

  String? locationError;
  String? paymentError;

  List<LocationSuggestionModel> suggestions = [];
  final List<LocationModel> recentAddresses = [];

  double? distanceKm;
  int? estimatedTimeMin;
  String? routeDuration;
  double? deliveryFee;
  double? serviceFee;
  double? totalAmount;
  String? currency;
  String? routePolyline;

  String? appliedPromoCode;
  double promoDiscount = 0;
  double? promoValidatedFinalAmount;
  String? promoMessage;

  String? pickupRequestToken;
  String? pickupRequestLink;
  String? pickupRequestStatus;

  String? dropoffRequestToken;
  String? dropoffRequestLink;
  String? dropoffRequestStatus;

  String senderName = '';
  String senderCode = '+234';
  String senderPhone = '';
  String senderEmail = '';

  String currentUserId = '';

  String receiverName = '';
  String receiverCode = '+234';
  String receiverPhone = '';
  String receiverEmail = '';

  String? selectedPackageType;
  String packageDescription = 'Package delivery';
  double packageWeightKg = 1;
  int packageQuantity = 1;
  bool packageIsFragile = false;
  bool applyProtection = false;

  String paymentMethod = 'paystack';

  String? createdOrderId;
  String? paymentReference;
  String? paymentAuthorizationUrl;
  String? paymentAccessCode;
  bool paymentSuccessful = false;

  Timer? _pickupPollingTimer;
  Timer? _dropoffPollingTimer;

  // Prevent an older autocomplete request from overwriting a newer search.
  int _addressSearchRequestId = 0;

  double get payableAmount {
    if (promoValidatedFinalAmount != null) {
      return promoValidatedFinalAmount!;
    }
    return totalAmount ?? 0;
  }

  void setSenderName(String value) {
    senderName = value;
    notifyListeners();
  }

  void setSenderCode(String value) {
    senderCode = value;
    notifyListeners();
  }

  void setSenderPhone(String value) {
    senderPhone = value;
    notifyListeners();
  }

  void setSenderEmail(String value) {
    senderEmail = value;
    notifyListeners();
  }

  void setReceiverName(String value) {
    receiverName = value;
    notifyListeners();
  }

  void setReceiverCode(String value) {
    receiverCode = value;
    notifyListeners();
  }

  void setReceiverPhone(String value) {
    receiverPhone = value;
    notifyListeners();
  }

  void setReceiverEmail(String value) {
    receiverEmail = value;
    notifyListeners();
  }

  void setPackageType(String? value) {
    selectedPackageType = value;
    if (packageDescription.trim().isEmpty &&
        value != null &&
        value.isNotEmpty) {
      packageDescription = value;
    }
    notifyListeners();
  }

  void setPackageDescription(String value) {
    packageDescription = value;
    notifyListeners();
  }

  void setPackageWeightKg(double value) {
    packageWeightKg = value;
    notifyListeners();
  }

  void setPackageQuantity(int value) {
    packageQuantity = value;
    notifyListeners();
  }

  void setPackageFragile(bool value) {
    packageIsFragile = value;
    notifyListeners();
  }

  void setApplyProtection(bool value) {
    applyProtection = value;
    notifyListeners();
  }

  void setPaymentMethod(String value) {
    if (paymentMethod != value) {
      paymentMethod = value;

      createdOrderId = null;
      paymentReference = null;
      paymentAuthorizationUrl = null;
      paymentAccessCode = null;

      notifyListeners();
    }
  }

  void setCurrentUserId(String value) {
    currentUserId = value;
    notifyListeners();
  }

  void clearPromo({bool notify = true}) {
    appliedPromoCode = null;
    promoDiscount = 0;
    promoValidatedFinalAmount = null;
    promoMessage = null;
    createdOrderId = null;

    if (notify) {
      notifyListeners();
    }
  }

  void clearLocationError({bool notify = true}) {
    locationError = null;
    if (notify) {
      notifyListeners();
    }
  }

  void _setLocationError(String message, {bool notify = true}) {
    locationError = message;
    if (notify) {
      notifyListeners();
    }
  }

  void applyValidatedPromo({
    required String code,
    required double discount,
    required double finalAmount,
    String? message,
  }) {
    appliedPromoCode = code;
    promoDiscount = discount;
    promoValidatedFinalAmount = finalAmount;
    promoMessage = message;
    createdOrderId = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>> validatePromoCode(String code) async {
    if (pickupLocation == null || dropoffLocation == null) {
      throw Exception('Pickup and drop-off locations are required');
    }

    final result = await _orderApiService.validatePromo(
      code: code.trim().toUpperCase(),
      pickupLat: pickupLocation!.latitude,
      pickupLng: pickupLocation!.longitude,
      deliveryLat: dropoffLocation!.latitude,
      deliveryLng: dropoffLocation!.longitude,
    );

    final data = result['data'] as Map<String, dynamic>? ?? {};

    final isValid = data['isValid'] == true;
    final isApplicable = data['isApplicable'] == true;

    if (!isValid || !isApplicable) {
      clearPromo(notify: false);
      promoMessage = result['message']?.toString();
      notifyListeners();
      return result;
    }

    final promoCode =
        data['promoCode']?.toString() ?? code.trim().toUpperCase();
    final discount = (data['discount'] as num?)?.toDouble() ?? 0;
    final finalAmount = (data['finalAmount'] as num?)?.toDouble() ?? 0;

    applyValidatedPromo(
      code: promoCode,
      discount: discount,
      finalAmount: finalAmount,
      message: result['message']?.toString(),
    );

    return result;
  }

  Future<void> loadPickupLocation() async {
    try {
      isGettingCurrentLocation = true;
      locationError = null;
      notifyListeners();

      final location = await _locationService.getCurrentLocation();

      pickupLocation = location;
      pickupAddress = location.address;
      locationError = null;

      _addToRecent(location);
    } catch (e) {
      _setLocationError('Current location error: $e', notify: false);
    } finally {
      isGettingCurrentLocation = false;
      notifyListeners();
    }
  }

  Future<LocationModel?> fetchCurrentLocationOnly() async {
    try {
      isGettingCurrentLocation = true;
      locationError = null;
      notifyListeners();

      final location = await _locationService.getCurrentLocation();
      locationError = null;
      return location;
    } catch (e) {
      _setLocationError('Current location error: $e', notify: false);
      return null;
    } finally {
      isGettingCurrentLocation = false;
      notifyListeners();
    }
  }

  Future<void> searchAddresses(String query) async {
    final cleanQuery = query.trim();

    if (cleanQuery.length < 2) {
      _addressSearchRequestId++;
      suggestions = [];
      isSearchingAddresses = false;
      hasAddressNetworkError = false;
      locationError = null;
      notifyListeners();
      return;
    }

    final requestId = ++_addressSearchRequestId;

    isSearchingAddresses = true;
    hasAddressNetworkError = false;
    locationError = null;
    notifyListeners();

    try {
      final results = await _locationService.searchAddresses(cleanQuery);

      // Ignore stale results if the user has already typed a newer query.
      if (requestId != _addressSearchRequestId) {
        return;
      }

      suggestions = results;
      hasAddressNetworkError = false;
      locationError = null;
    } on LocationServiceException catch (e) {
      if (requestId != _addressSearchRequestId) {
        return;
      }

      if (e.type == LocationServiceErrorType.network) {
        // Do not clear previous suggestions on a temporary network failure.
        hasAddressNetworkError = true;
        locationError = 'Having trouble loading locations. Please try again.';
      } else {
        suggestions = [];
        hasAddressNetworkError = false;
        locationError = e.message;
      }
    } catch (_) {
      if (requestId != _addressSearchRequestId) {
        return;
      }

      suggestions = [];
      hasAddressNetworkError = false;
      locationError = 'Unable to search locations right now. Please try again.';
    } finally {
      if (requestId == _addressSearchRequestId) {
        isSearchingAddresses = false;
        notifyListeners();
      }
    }
  }

  Future<LocationModel?> selectSuggestion(
    LocationSuggestionModel suggestion,
  ) async {
    try {
      locationError = null;
      notifyListeners();

      final location = await _locationService.getPlaceDetails(
        suggestion.placeId,
      );

      final selectedName = suggestion.title.trim();

      final updatedLocation = LocationModel(
        latitude: location.latitude,
        longitude: location.longitude,
        address: location.address,
        name: selectedName.isNotEmpty ? selectedName : null,
        shortAddress: location.shortAddress,
        placeId: location.placeId,
        city: location.city,
        state: location.state,
        country: location.country,
      );

      locationError = null;
      return updatedLocation;
    } catch (e) {
      _setLocationError('Place details error: $e', notify: false);
      notifyListeners();
      return null;
    }
  }

  void setPickupLocation(LocationModel location, {bool addToRecent = false}) {
    pickupLocation = location;
    pickupAddress = location.address;
    locationError = null;

    if (addToRecent) {
      _addToRecent(location);
    }

    _resetEstimateValues();
    notifyListeners();
  }

  void setDropoffLocation(LocationModel location, {bool addToRecent = false}) {
    dropoffLocation = location;
    dropoffAddress = location.address;
    locationError = null;

    if (addToRecent) {
      _addToRecent(location);
    }

    _resetEstimateValues();
    notifyListeners();
  }

  Future<void> calculateDistanceAndFee() async {
    await fetchEstimate();
  }

  Future<void> fetchEstimate() async {
    if (pickupLocation == null || dropoffLocation == null) return;

    try {
      isCalculatingRoute = true;
      locationError = null;
      notifyListeners();

      final OrderEstimateModel estimate = await _orderEstimateApiService
          .fetchEstimate(
            pickupLat: pickupLocation!.latitude,
            pickupLng: pickupLocation!.longitude,
            deliveryLat: dropoffLocation!.latitude,
            deliveryLng: dropoffLocation!.longitude,
          );

      distanceKm = estimate.distanceKm;
      estimatedTimeMin = estimate.estimatedTimeMin;
      routeDuration = '${estimate.estimatedTimeMin} min';
      deliveryFee = estimate.deliveryFee;
      serviceFee = estimate.serviceFee;
      totalAmount = estimate.amount;
      currency = estimate.currency;
      routePolyline = null;

      locationError = null;
      clearPromo(notify: false);
    } catch (e) {
      final message = e.toString();

      if (message.contains('HandshakeException') ||
          message.contains('timeout') ||
          message.contains('SocketException')) {
        locationError =
            'Network is unstable. Please try again or switch network.';
      } else {
        locationError = 'Estimate error: $e';
      }

      _resetEstimateValues();
    } finally {
      isCalculatingRoute = false;
      notifyListeners();
    }
  }

  Future<void> createPickupLocationRequest() async {
    try {
      isCreatingPickupRequest = true;
      locationError = null;
      notifyListeners();

      final result = await _locationRequestApiService.createLocationRequest();

      pickupRequestToken = result.token;
      pickupRequestLink = result.link;
      pickupRequestStatus = result.status;
      locationError = null;

      _startPickupPolling();
    } catch (e) {
      _setLocationError('Pickup request error: $e', notify: false);
    } finally {
      isCreatingPickupRequest = false;
      notifyListeners();
    }
  }

  Future<void> createDropoffLocationRequest() async {
    try {
      isCreatingDropoffRequest = true;
      locationError = null;
      notifyListeners();

      final result = await _locationRequestApiService.createLocationRequest();

      dropoffRequestToken = result.token;
      dropoffRequestLink = result.link;
      dropoffRequestStatus = result.status;
      locationError = null;

      _startDropoffPolling();
    } catch (e) {
      _setLocationError('Dropoff request error: $e', notify: false);
    } finally {
      isCreatingDropoffRequest = false;
      notifyListeners();
    }
  }

  Future<void> refreshPickupLocationRequest() async {
    if (pickupRequestToken == null) return;

    try {
      isRefreshingPickupRequest = true;
      locationError = null;
      notifyListeners();

      final result = await _locationRequestApiService.getLocationRequestStatus(
        pickupRequestToken!,
      );

      pickupRequestStatus = result.status;

      if (result.isConfirmed) {
        final location = await _locationService.reverseGeocode(
          latitude: result.latitude!,
          longitude: result.longitude!,
        );

        setPickupLocation(location, addToRecent: true);
        _stopPickupPolling();
        locationError = null;

        if (dropoffLocation != null) {
          await fetchEstimate();
        }
      } else if (result.isExpired) {
        _stopPickupPolling();
      }
    } catch (e) {
      _setLocationError('Refresh pickup request error: $e', notify: false);
    } finally {
      isRefreshingPickupRequest = false;
      notifyListeners();
    }
  }

  Future<void> refreshDropoffLocationRequest() async {
    if (dropoffRequestToken == null) return;

    try {
      isRefreshingDropoffRequest = true;
      locationError = null;
      notifyListeners();

      final result = await _locationRequestApiService.getLocationRequestStatus(
        dropoffRequestToken!,
      );

      dropoffRequestStatus = result.status;

      if (result.isConfirmed) {
        final location = await _locationService.reverseGeocode(
          latitude: result.latitude!,
          longitude: result.longitude!,
        );

        setDropoffLocation(location, addToRecent: true);
        _stopDropoffPolling();
        locationError = null;

        if (pickupLocation != null) {
          await fetchEstimate();
        }
      } else if (result.isExpired) {
        _stopDropoffPolling();
      }
    } catch (e) {
      _setLocationError('Refresh dropoff request error: $e', notify: false);
    } finally {
      isRefreshingDropoffRequest = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> buildCreateOrderPayload() {
    if (pickupLocation == null) {
      throw Exception('Pickup location is required');
    }

    if (dropoffLocation == null) {
      throw Exception('Drop-off location is required');
    }

    if (receiverName.trim().isEmpty) {
      throw Exception('Receiver name is required');
    }

    if (receiverPhone.trim().isEmpty) {
      throw Exception('Receiver phone is required');
    }

    if (senderName.trim().isEmpty) {
      throw Exception('Sender name is required');
    }

    if (senderPhone.trim().isEmpty) {
      throw Exception('Sender phone is required');
    }

    // Email is optional: the other contact only provides name and phone.

    if ((selectedPackageType ?? '').trim().isEmpty) {
      throw Exception('Package type is required');
    }

    final normalizedSenderPhone = _normalizePhone(senderCode, senderPhone);
    final normalizedReceiverPhone = _normalizePhone(
      receiverCode,
      receiverPhone,
    );

    return {
      'userId': currentUserId,
      'pickup': {
        'address': _formatLocationAddress(pickupLocation!),
        'lat': pickupLocation!.latitude,
        'lng': pickupLocation!.longitude,
        'instructions': 'Pickup location selected in app',
      },
      'delivery': {
        'address': _formatLocationAddress(dropoffLocation!),
        'lat': dropoffLocation!.latitude,
        'lng': dropoffLocation!.longitude,
        'instructions': 'Drop-off location selected in app',
      },
      'sender': {
        'name': senderName.trim(),
        'phone': normalizedSenderPhone,
        'email': senderEmail.trim(),
      },
      'receiver': {
        'name': receiverName.trim(),
        'phone': normalizedReceiverPhone,
        'email': receiverEmail.trim(),
      },
      'package': {
        'type': selectedPackageType!.trim().toLowerCase(),
        'description': packageDescription.trim().isEmpty
            ? selectedPackageType!.trim()
            : packageDescription.trim(),
        'weightKg': packageWeightKg,
        'quantity': packageQuantity,
        'isFragile': packageIsFragile,
      },
      'payment': {'method': paymentMethod},
      'promoCode': appliedPromoCode,
    };
  }

  Future<void> createOrderIfNeeded() async {
    if (createdOrderId != null && createdOrderId!.isNotEmpty) {
      return;
    }

    try {
      isCreatingOrder = true;
      paymentError = null;
      notifyListeners();

      final payload = buildCreateOrderPayload();
      final result = await _orderApiService.createOrder(payload: payload);

      final data = result['data'] as Map<String, dynamic>?;

      final orderId = data?['orderId']?.toString();
      if (orderId == null || orderId.isEmpty) {
        throw Exception('Order created but orderId is missing');
      }

      createdOrderId = orderId;
    } catch (e) {
      paymentError = e.toString();
      rethrow;
    } finally {
      isCreatingOrder = false;
      notifyListeners();
    }
  }

  Future<void> initializePaystackPayment() async {
    if (paymentMethod != 'paystack' && paymentMethod != 'bank_transfer') {
      throw Exception('Only Paystack is currently supported here');
    }

    await createOrderIfNeeded();

    if (createdOrderId == null || createdOrderId!.isEmpty) {
      throw Exception('Order ID is missing');
    }

    try {
      isInitializingPayment = true;
      paymentError = null;
      notifyListeners();

      final result = await _orderApiService.initializePayment(
        orderId: createdOrderId!,
      );

      final data = result['data'] as Map<String, dynamic>?;

      paymentReference = data?['reference']?.toString();
      paymentAuthorizationUrl = data?['authorizationUrl']?.toString();
      paymentAccessCode = data?['accessCode']?.toString();

      if (paymentAuthorizationUrl == null || paymentAuthorizationUrl!.isEmpty) {
        throw Exception('Payment URL is missing');
      }
    } catch (e) {
      paymentError = e.toString();
      rethrow;
    } finally {
      isInitializingPayment = false;
      notifyListeners();
    }
  }

  Future<void> preparePaystackCheckout() async {
    try {
      isPaying = true;
      paymentError = null;
      paymentSuccessful = false;
      notifyListeners();

      await initializePaystackPayment();
    } catch (e) {
      paymentError = e.toString();
      rethrow;
    } finally {
      isPaying = false;
      notifyListeners();
    }
  }

  Future<bool> verifyCompletedPayment({String? returnedReference}) async {
    final reference = returnedReference?.trim().isNotEmpty == true
        ? returnedReference!.trim()
        : paymentReference?.trim();

    if (reference == null || reference.isEmpty) {
      throw Exception('Payment reference is missing');
    }

    try {
      isVerifyingPayment = true;
      paymentError = null;
      notifyListeners();

      final result = await _orderApiService.verifyPayment(reference: reference);
      final data = result['data'] as Map<String, dynamic>?;

      final verifiedReference = data?['reference']?.toString();
      if (verifiedReference != null && verifiedReference.isNotEmpty) {
        paymentReference = verifiedReference;
      } else {
        paymentReference = reference;
      }

      paymentSuccessful = true;
      return true;
    } catch (e) {
      paymentError = e.toString();
      paymentSuccessful = false;
      return false;
    } finally {
      isVerifyingPayment = false;
      notifyListeners();
    }
  }

  void resetPaymentState({bool keepCreatedOrder = true}) {
    paymentError = null;
    paymentReference = null;
    paymentAuthorizationUrl = null;
    paymentAccessCode = null;
    paymentSuccessful = false;

    if (!keepCreatedOrder) {
      createdOrderId = null;
    }

    notifyListeners();
  }

  String _normalizePhone(String code, String phone) {
    final cleanCode = code.trim();
    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '').trim();

    if (cleanPhone.startsWith('+')) {
      return cleanPhone;
    }

    if (cleanPhone.startsWith('0')) {
      return '$cleanCode${cleanPhone.substring(1)}';
    }

    return '$cleanCode$cleanPhone';
  }

  void _startPickupPolling() {
    _stopPickupPolling();
    _pickupPollingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => refreshPickupLocationRequest(),
    );
  }

  void _startDropoffPolling() {
    _stopDropoffPolling();
    _dropoffPollingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => refreshDropoffLocationRequest(),
    );
  }

  void _stopPickupPolling() {
    _pickupPollingTimer?.cancel();
    _pickupPollingTimer = null;
  }

  void _stopDropoffPolling() {
    _dropoffPollingTimer?.cancel();
    _dropoffPollingTimer = null;
  }

  void _resetEstimateValues() {
    distanceKm = null;
    estimatedTimeMin = null;
    routeDuration = null;
    deliveryFee = null;
    serviceFee = null;
    totalAmount = null;
    currency = null;
    routePolyline = null;
    clearPromo(notify: false);
  }

  void _addToRecent(LocationModel location) {
    recentAddresses.removeWhere(
      (item) =>
          item.address.toLowerCase().trim() ==
          location.address.toLowerCase().trim(),
    );

    recentAddresses.insert(0, location);

    if (recentAddresses.length > 8) {
      recentAddresses.removeLast();
    }
  }

  void clearSuggestions({bool notify = true}) {
    // Invalidate any autocomplete request that is still in flight.
    _addressSearchRequestId++;

    suggestions = [];
    isSearchingAddresses = false;
    hasAddressNetworkError = false;
    locationError = null;

    if (notify) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _addressSearchRequestId++;
    _stopPickupPolling();
    _stopDropoffPolling();
    super.dispose();
  }

  Future<bool> createOrderOnly() async {
    try {
      isCreatingOrder = true;
      paymentError = null;
      paymentSuccessful = false;
      notifyListeners();

      final payload = buildCreateOrderPayload();
      final result = await _orderApiService.createOrder(payload: payload);

      final data = result['data'] as Map<String, dynamic>?;
      final orderId = data?['orderId']?.toString();

      if (orderId == null || orderId.isEmpty) {
        throw Exception('Order created but orderId is missing');
      }

      createdOrderId = orderId;
      return true;
    } catch (e) {
      paymentError = e.toString();
      return false;
    } finally {
      isCreatingOrder = false;
      notifyListeners();
    }
  }
}