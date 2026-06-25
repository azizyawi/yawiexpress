import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wanmac/config/google_places_config.dart';
import 'package:wanmac/core/theme/app_colors.dart';
import 'package:wanmac/core/utils/app_snackbar.dart';
import 'package:wanmac/models/order_model.dart';
import 'package:wanmac/services/order_api_service.dart';
import 'package:wanmac/views/screens/main/main_screen.dart';
import 'package:wanmac/views/screens/wanny/wanny_chat_screen.dart';

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

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  final OrderApiService orderApiService;

  /// Pass this from the orders list/details screen so this screen opens instantly.
  /// Live tracking will still refresh silently after opening.
  final OrderModel? initialOrder;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
    required this.orderApiService,
    this.initialOrder,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  OrderModel? order;
  Timer? _pollTimer;
  GoogleMapController? _mapController;
  BitmapDescriptor? riderIcon;

  bool isLoading = true;
  bool isCancelling = false;
  String? error;
  bool isFollowingRider = true;

  List<LatLng> routePoints = [];

  @override
  void initState() {
    super.initState();

    order = widget.initialOrder;
    isLoading = widget.initialOrder == null;

    _loadCustomMarker();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrder(silent: widget.initialOrder != null);
    });

    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!isCancelling && mounted) {
        _loadOrder(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _goToOrdersTab() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 1)),
      (route) => false,
    );
  }

  Future<void> _loadCustomMarker() async {
    try {
      final ByteData data = await rootBundle.load('assets/images/rider.png');
      final Uint8List bytes = data.buffer.asUint8List();

      final ui.Codec codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 96,
      );

      final ui.FrameInfo fi = await codec.getNextFrame();
      final Uint8List resizedBytes = (await fi.image.toByteData(
        format: ui.ImageByteFormat.png,
      ))!.buffer.asUint8List();

      final BitmapDescriptor bitmap = BitmapDescriptor.fromBytes(resizedBytes);

      if (!mounted) return;

      setState(() {
        riderIcon = bitmap;
      });
    } catch (_) {
      // Keep default marker if custom image fails.
    }
  }

  bool _distanceChanged(LatLng oldPoint, LatLng newPoint) {
    final latDiff = (oldPoint.latitude - newPoint.latitude).abs();
    final lngDiff = (oldPoint.longitude - newPoint.longitude).abs();

    return latDiff > 0.0003 || lngDiff > 0.0003;
  }

  Future<void> _loadOrder({bool silent = false}) async {
    try {
      if (!silent && order == null) {
        setState(() {
          isLoading = true;
          error = null;
        });
      }

      final oldRiderPoint = riderPoint;
      final oldStatus = order?.status;

      final response = await widget.orderApiService.getOrderById(
        orderId: widget.orderId,
      );

      final data = response['data'] ?? response;
      final newOrder = OrderModel.fromJson(data);

      if (!mounted) return;

      setState(() {
        order = newOrder;
        isLoading = false;
        error = null;
      });

      final newRiderPoint = riderPoint;
      final statusChanged = oldStatus != order?.status;

      final shouldRefreshRoute =
          !silent ||
          statusChanged ||
          oldRiderPoint == null ||
          newRiderPoint == null ||
          _distanceChanged(oldRiderPoint, newRiderPoint);

      if (shouldRefreshRoute) {
        _getRoutePolyline();
      }

      if (!mounted) return;

      if (silent && isFollowingRider) {
        _followRider();
      } else if (!silent) {
        _fitMap();
      }
    } catch (e) {
      if (!mounted) return;

      if (!silent && order == null) {
        setState(() {
          isLoading = false;
          error = e.toString();
        });
      }
    }
  }

  Future<void> _cancelOrder() async {
    if (isCancelling) return;

    Navigator.pop(context);

    setState(() {
      isCancelling = true;
    });

    try {
      await widget.orderApiService.cancelOrder(orderId: widget.orderId);

      if (!mounted) return;

      AppSnackBar.show(
        context,
        message: "Order cancelled successfully",
        type: AppSnackBarType.success,
      );

      _goToOrdersTab();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isCancelling = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception:', '').trim()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showCancelSheet() {
    if (!canCancelOrder || isCancelling) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: !isCancelling,
      enableDrag: !isCancelling,
      builder: (_) {
        final s = _scale(context);
        double r(double value) => value * s;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: _maxContentWidth(context)),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(r(20), r(16), r(20), r(24)),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(r(28)),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: r(44),
                      height: r(5),
                      decoration: BoxDecoration(
                        color: AppColors.inputBorder,
                        borderRadius: BorderRadius.circular(r(100)),
                      ),
                    ),
                    SizedBox(height: r(22)),
                    Container(
                      width: r(58),
                      height: r(58),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(r(20)),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: AppColors.error,
                        size: r(34),
                      ),
                    ),
                    SizedBox(height: r(18)),
                    Text(
                      'Cancel this order?',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: r(20),
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: r(8)),
                    Text(
                      'This will cancel the delivery request. If a rider has already been assigned, they will be released from this order.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: r(13),
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                    SizedBox(height: r(24)),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              height: r(52),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.inputFill,
                                borderRadius: BorderRadius.circular(r(16)),
                                border: Border.all(
                                  color: AppColors.inputBorder,
                                ),
                              ),
                              child: Text(
                                'Keep Order',
                                style: GoogleFonts.montserrat(
                                  fontSize: r(13),
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: r(12)),
                        Expanded(
                          child: GestureDetector(
                            onTap: _cancelOrder,
                            child: Container(
                              height: r(52),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(r(16)),
                              ),
                              child: Text(
                                'Cancel Order',
                                style: GoogleFonts.montserrat(
                                  fontSize: r(13),
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Future<void> _getRoutePolyline() async {
    final rider = riderPoint;

    if (order == null ||
        isDelivered ||
        isCancelled ||
        !hasRider ||
        rider == null) {
      if (!mounted) return;
      setState(() => routePoints = []);
      return;
    }

    try {
      final polylinePoints = PolylinePoints(apiKey: GooglePlacesConfig.apiKey);

      final result = await polylinePoints.getRouteBetweenCoordinates(
        request: PolylineRequest(
          origin: PointLatLng(rider.latitude, rider.longitude),
          destination: PointLatLng(
            activeDestinationPoint.latitude,
            activeDestinationPoint.longitude,
          ),
          mode: TravelMode.driving,
        ),
      );

      if (!mounted) return;

      setState(() {
        routePoints = result.points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => routePoints = []);
    }
  }

  Future<void> _followRider() async {
    final rider = riderPoint;
    if (_mapController == null || rider == null || isDelivered || isCancelled) {
      return;
    }

    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: rider,
          zoom: 15.5,
          tilt: 45,
          bearing: order?.rider.heading ?? 0,
        ),
      ),
    );
  }

  Future<void> _recenterToRider() async {
    setState(() {
      isFollowingRider = true;
    });
    await _followRider();
  }

  Future<void> _callRider() async {
    final phone = order?.rider.phone?.trim();

    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rider phone number is unavailable')),
      );
      return;
    }

    final uri = Uri.parse('tel:$phone');

    try {
      await launchUrl(uri);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open phone dialer')),
      );
    }
  }

  bool get hasRider {
    final riderId = order?.rider.riderId;
    return riderId != null && riderId.trim().isNotEmpty;
  }

  bool get isDelivered {
    final status = order?.status.toLowerCase() ?? '';
    return status.contains('delivered');
  }

  bool get isCancelled {
    final status = order?.status.toLowerCase() ?? '';
    return status.contains('cancelled') || status.contains('canceled');
  }

  bool get hasPickedUp {
    final status = order?.status.toLowerCase() ?? '';
    return status.contains('picked') ||
        status.contains('arrived_delivery') ||
        status.contains('delivered');
  }

  bool get hasArrivedPickup {
    final status = order?.status.toLowerCase() ?? '';
    return status.contains('arrived_pickup');
  }

  bool get hasArrivedDelivery {
    final status = order?.status.toLowerCase() ?? '';
    return status.contains('arrived_delivery');
  }

  bool get canCancelOrder {
    if (order == null) return false;
    if (isDelivered || isCancelled || hasPickedUp) return false;
    return true;
  }

  LatLng get pickupPoint => LatLng(order!.pickup.lat, order!.pickup.lng);

  LatLng get deliveryPoint => LatLng(order!.delivery.lat, order!.delivery.lng);

  LatLng? get riderPoint {
    final lat = order?.rider.lat;
    final lng = order?.rider.lng;

    if (lat == null || lng == null) return null;

    return LatLng(lat, lng);
  }

  LatLng get activeDestinationPoint {
    if (hasRider && hasPickedUp) return deliveryPoint;
    return pickupPoint;
  }

  String get riderDisplayName {
    final name = order?.rider.name?.trim();
    if (name == null || name.isEmpty) return 'Your rider';
    return name;
  }

  double? get riderDistanceToDestinationKm {
    final rider = riderPoint;
    if (order == null || rider == null || !hasRider) return null;
    return _calculateDistanceKm(rider, activeDestinationPoint);
  }

  int? get estimatedArrivalMinutes {
    final distanceKm = riderDistanceToDestinationKm;
    if (distanceKm == null) return null;

    final speedKmPerHour = hasPickedUp ? 22.0 : 18.0;
    final minutes = ((distanceKm / speedKmPerHour) * 60).ceil();

    return minutes.clamp(1, 99);
  }

  String get formattedRiderDistance {
    final distanceKm = riderDistanceToDestinationKm;
    if (distanceKm == null) return '';

    if (distanceKm < 1) {
      final meters = (distanceKm * 1000).round();
      return '${meters.clamp(1, 999)}m';
    }

    return '${distanceKm.toStringAsFixed(1)}km';
  }

  double _calculateDistanceKm(LatLng start, LatLng end) {
    const earthRadiusKm = 6371.0;

    final dLat = _degreesToRadians(end.latitude - start.latitude);
    final dLng = _degreesToRadians(end.longitude - start.longitude);

    final lat1 = _degreesToRadians(start.latitude);
    final lat2 = _degreesToRadians(end.latitude);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  String get titleText {
    final eta = estimatedArrivalMinutes;

    if (isCancelled) return 'Order cancelled';
    if (isDelivered) return 'Delivery completed';

    if (!hasRider) return 'Finding nearby rider';

    if (hasArrivedDelivery) return 'Rider has arrived';
    if (hasArrivedPickup && !hasPickedUp) return 'Rider is at pickup';

    if (eta != null) {
      if (eta <= 2) return 'Arriving now';
      return 'Arriving in $eta mins';
    }

    if (hasPickedUp) return 'Rider is heading to delivery';

    return 'Rider is coming to pickup';
  }

  String get subtitleText {
    final eta = estimatedArrivalMinutes;
    final distance = formattedRiderDistance;

    if (isCancelled) {
      return 'This delivery request has been cancelled.';
    }

    if (isDelivered) {
      return 'Your package has been delivered successfully.';
    }

    if (!hasRider) {
      return 'We are finding a nearby rider for your delivery.';
    }

    if (hasArrivedDelivery) {
      return '$riderDisplayName is waiting at the delivery location.';
    }

    if (hasArrivedPickup && !hasPickedUp) {
      return '$riderDisplayName is waiting at the pickup location.';
    }

    if (hasPickedUp) {
      if (eta != null && distance.isNotEmpty) {
        return '$riderDisplayName is $distance from the delivery point.';
      }

      return '$riderDisplayName has picked up your package.';
    }

    if (eta != null && distance.isNotEmpty) {
      return '$riderDisplayName is $distance from the pickup point.';
    }

    return '$riderDisplayName has accepted your order.';
  }

  String get smartInfoMessage {
    final eta = estimatedArrivalMinutes;

    if (isCancelled) {
      return 'This order has been cancelled.';
    }

    if (isDelivered) {
      return 'Your delivery has been completed successfully.';
    }

    if (!hasRider) {
      return 'Searching for a nearby rider around your pickup location.';
    }

    if (hasArrivedDelivery) {
      return 'Your rider is at the delivery point. Please share the delivery PIN.';
    }

    if (hasArrivedPickup && !hasPickedUp) {
      return 'Your rider is at pickup. Please share the pickup PIN.';
    }

    if (hasPickedUp) {
      if (eta != null) {
        return eta <= 2
            ? 'Your package is almost at the delivery location.'
            : 'Your package should arrive in about $eta mins.';
      }

      return 'Your rider is heading to the delivery location.';
    }

    if (eta != null) {
      return eta <= 2
          ? 'Your rider is almost at the pickup location.'
          : 'Your rider should reach pickup in about $eta mins.';
    }

    return 'Your rider is heading to the pickup location.';
  }

  String get pinLabel => hasPickedUp ? 'Delivery PIN' : 'Pickup PIN';

  String get currentPin {
    if (order == null || isDelivered || isCancelled) return '';
    return hasPickedUp ? order!.pins.deliveryPin : order!.pins.pickupPin;
  }

  double get progressValue {
    final status = order?.status.toLowerCase() ?? '';

    if (isCancelled) return 0.0;
    if (isDelivered) return 1.0;
    if (!hasRider) return 0.20;
    if (status.contains('accepted')) return 0.35;
    if (status.contains('arrived_pickup')) return 0.50;
    if (status.contains('picked')) return 0.65;
    if (status.contains('arrived_delivery')) return 0.85;

    return 0.35;
  }

  Set<Marker> _buildMarkers() {
    if (order == null) return {};

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('pickup'),
        position: pickupPoint,
        infoWindow: InfoWindow(title: 'Pickup', snippet: order!.pickup.address),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
      Marker(
        markerId: const MarkerId('delivery'),
        position: deliveryPoint,
        infoWindow: InfoWindow(
          title: 'Dropoff',
          snippet: order!.delivery.address,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    };

    final rider = riderPoint;

    if (hasRider && rider != null && !isDelivered && !isCancelled) {
      markers.add(
        Marker(
          markerId: const MarkerId('rider'),
          position: rider,
          rotation: order!.rider.heading ?? 0,
          anchor: const Offset(0.5, 0.8),
          flat: true,
          infoWindow: InfoWindow(
            title: order!.rider.name ?? 'Rider',
            snippet: order!.rider.phone ?? '',
          ),
          icon:
              riderIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _buildPolylines() {
    if (order == null) return {};

    final rider = riderPoint;
    final polylines = <Polyline>{};

    polylines.add(
      Polyline(
        polylineId: const PolylineId('pickup_to_delivery'),
        color: AppColors.brandBlueDark.withValues(alpha: 0.15),
        width: 2,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        points: [pickupPoint, deliveryPoint],
      ),
    );

    if (!isDelivered && !isCancelled && hasRider && rider != null) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('active_route'),
          color: AppColors.brandBlueDark,
          width: 4,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          points: routePoints.isNotEmpty
              ? routePoints
              : [rider, activeDestinationPoint],
        ),
      );
    }

    return polylines;
  }

  Future<void> _fitMap() async {
    if (_mapController == null || order == null) return;

    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    final rider = riderPoint;

    final points = <LatLng>[
      if (!isDelivered && !isCancelled && hasRider && rider != null) rider,
      activeDestinationPoint,
      if (routePoints.isNotEmpty) ...routePoints,
    ];

    if (points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLng = point.longitude < minLng ? point.longitude : minLng;
      maxLng = point.longitude > maxLng ? point.longitude : maxLng;
    }

    final samePoint = minLat == maxLat && minLng == maxLng;

    if (samePoint) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: points.first,
            zoom: 15.5,
            tilt: hasRider && !isDelivered && !isCancelled ? 45 : 0,
          ),
        ),
      );
      return;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 300));
  }

  void _showActiveAddressInfoWindow() {
    Future.delayed(const Duration(milliseconds: 700), () {
      if (_mapController == null || order == null || !mounted) return;

      _mapController?.showMarkerInfoWindow(
        MarkerId(hasPickedUp ? 'delivery' : 'pickup'),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.montserratTextTheme(
      Theme.of(context).textTheme,
    );

    final shouldShowFullLoader = order == null && isLoading;

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: textTheme,
        scaffoldBackgroundColor: AppColors.background,
      ),
      child: PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          if (didPop) return;
          _goToOrdersTab();
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: shouldShowFullLoader
              ? const Center(child: CircularProgressIndicator())
              : error != null && order == null
              ? _ErrorView(message: error!, onRetry: _loadOrder)
              : SafeArea(
                  bottom: false,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: _maxContentWidth(context),
                      ),
                      child: Stack(
                        children: [
                          Column(
                            children: [
                              _TopStatusCard(
                                title: titleText,
                                subtitle: subtitleText,
                                progressValue: progressValue,
                                isDelivered: isDelivered,
                                isCancelled: isCancelled,
                                canCancelOrder: canCancelOrder,
                                isCancelling: isCancelling,
                                onBack: _goToOrdersTab,
                                onDone: _goToOrdersTab,
                                onCancel: _showCancelSheet,
                              ),
                              if (hasRider && !isDelivered && !isCancelled)
                                _RiderStrip(
                                  order: order!,
                                  onCallRider: _callRider,
                                ),
                              Expanded(
                                child: Stack(
                                  children: [
                                    Opacity(
                                      opacity: isDelivered || isCancelled
                                          ? 0.55
                                          : 1,
                                      child: GoogleMap(
                                        initialCameraPosition: CameraPosition(
                                          target: pickupPoint,
                                          zoom: 14,
                                        ),
                                        markers: _buildMarkers(),
                                        polylines: _buildPolylines(),
                                        myLocationButtonEnabled: false,
                                        zoomControlsEnabled: false,
                                        mapToolbarEnabled: false,
                                        compassEnabled: false,
                                        buildingsEnabled: false,
                                        trafficEnabled: false,
                                        indoorViewEnabled: false,
                                        rotateGesturesEnabled: true,
                                        tiltGesturesEnabled: true,
                                        onCameraMoveStarted: () {
                                          if (isFollowingRider) {
                                            setState(() {
                                              isFollowingRider = false;
                                            });
                                          }
                                        },
                                        onMapCreated: (controller) async {
                                          _mapController = controller;

                                          _fitMap();
                                          _showActiveAddressInfoWindow();
                                        },
                                      ),
                                    ),
                                    if (hasRider &&
                                        !isDelivered &&
                                        !isCancelled &&
                                        !isFollowingRider)
                                      _RecenterButton(onTap: _recenterToRider),
                                  ],
                                ),
                              ),
                              _PinAndInfoSheet(
                                pinLabel: pinLabel,
                                pin: currentPin,
                                hasRider: hasRider,
                                hasPickedUp: hasPickedUp,
                                isDelivered: isDelivered,
                                isCancelled: isCancelled,
                                smartInfoMessage: smartInfoMessage,
                              ),
                            ],
                          ),
                          if (isCancelling)
                            Container(
                              color: Colors.black.withValues(alpha: 0.15),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _TopStatusCard extends StatelessWidget {
  Future<void> _openWannyChat(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    final userId = prefs.getString('userId') ?? '';
    final firstName = prefs.getString('firstName') ?? '';

    final name = firstName.trim();

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WannyChatScreen(
          userId: userId.isNotEmpty
              ? userId
              : DateTime.now().millisecondsSinceEpoch.toString(),
          userName: name.isNotEmpty ? name : null,
        ),
      ),
    );
  }

  final String title;
  final String subtitle;
  final double progressValue;
  final bool isDelivered;
  final bool isCancelled;
  final bool canCancelOrder;
  final bool isCancelling;
  final VoidCallback onBack;
  final VoidCallback onDone;
  final VoidCallback onCancel;

  const _TopStatusCard({
    required this.title,
    required this.subtitle,
    required this.progressValue,
    required this.isDelivered,
    required this.isCancelled,
    required this.canCancelOrder,
    required this.isCancelling,
    required this.onBack,
    required this.onDone,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    final statusFinished = isDelivered || isCancelled;

    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: EdgeInsets.fromLTRB(r(20), r(12), r(20), r(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: r(26),
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: statusFinished ? onDone : () => _openWannyChat(context),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: r(15),
                    vertical: r(9),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.infoBg,
                    borderRadius: BorderRadius.circular(r(100)),
                    border: Border.all(color: AppColors.infoBorder),
                  ),
                  child: Text(
                    statusFinished ? 'DONE' : 'NEED HELP?',
                    style: GoogleFonts.montserrat(
                      fontSize: r(11),
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandBlueDark,
                    ),
                  ),
                ),
              ),
              SizedBox(width: r(12)),
              Icon(
                statusFinished
                    ? Icons.check_circle_outline
                    : Icons.share_outlined,
                size: r(22),
                color: AppColors.brandBlueDark,
              ),
            ],
          ),
          SizedBox(height: r(20)),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              title,
              key: ValueKey(title),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.montserrat(
                fontSize: r(24),
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.6,
                height: 1.12,
              ),
            ),
          ),
          SizedBox(height: r(7)),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              subtitle,
              key: ValueKey(subtitle),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.montserrat(
                fontSize: r(13),
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
          SizedBox(height: r(16)),
          ClipRRect(
            borderRadius: BorderRadius.circular(r(100)),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: r(6),
              backgroundColor: AppColors.inputBorder,
              valueColor: AlwaysStoppedAnimation<Color>(
                isCancelled ? AppColors.error : AppColors.brandBlueDark,
              ),
            ),
          ),
          if (canCancelOrder) ...[
            SizedBox(height: r(14)),
            GestureDetector(
              onTap: isCancelling ? null : onCancel,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: r(13)),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(r(16)),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.22),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.close_rounded,
                      color: AppColors.error,
                      size: r(18),
                    ),
                    SizedBox(width: r(8)),
                    Text(
                      isCancelling ? 'Cancelling...' : 'Cancel Order',
                      style: GoogleFonts.montserrat(
                        fontSize: r(13),
                        fontWeight: FontWeight.w800,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RiderStrip extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onCallRider;

  const _RiderStrip({required this.order, required this.onCallRider});

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.fromLTRB(r(20), r(12), r(20), r(14)),
      child: Row(
        children: [
          Container(
            width: r(48),
            height: r(48),
            decoration: BoxDecoration(
              color: AppColors.infoBg,
              borderRadius: BorderRadius.circular(r(14)),
              border: Border.all(color: AppColors.infoBorder),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(r(14)),
              child: Image.asset('assets/images/rider.png', fit: BoxFit.cover),
            ),
          ),
          SizedBox(width: r(14)),
          Expanded(
            child: Text(
              order.rider.name ?? 'Your rider',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.montserrat(
                fontSize: r(14),
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          GestureDetector(
            onTap: onCallRider,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: r(15), vertical: r(10)),
              decoration: BoxDecoration(
                color: AppColors.infoBg,
                borderRadius: BorderRadius.circular(r(100)),
                border: Border.all(color: AppColors.infoBorder),
              ),
              child: Text(
                'CALL RIDER',
                style: GoogleFonts.montserrat(
                  fontSize: r(11),
                  fontWeight: FontWeight.w800,
                  color: AppColors.brandBlueDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinAndInfoSheet extends StatelessWidget {
  final String pinLabel;
  final String pin;
  final bool hasRider;
  final bool hasPickedUp;
  final bool isDelivered;
  final bool isCancelled;
  final String smartInfoMessage;

  const _PinAndInfoSheet({
    required this.pinLabel,
    required this.pin,
    required this.hasRider,
    required this.hasPickedUp,
    required this.isDelivered,
    required this.isCancelled,
    required this.smartInfoMessage,
  });

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: r(132)),
        color: AppColors.surface,
        padding: EdgeInsets.fromLTRB(r(20), r(14), r(20), r(18)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasRider && pin.isNotEmpty && !isDelivered && !isCancelled) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      hasPickedUp
                          ? 'Share this code with the receiver'
                          : 'Share this code with your rider',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: r(14),
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                  ),
                  ...pin
                      .split('')
                      .map(
                        (digit) => Container(
                          margin: EdgeInsets.only(left: r(8)),
                          width: r(42),
                          height: r(42),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.inputFill,
                            borderRadius: BorderRadius.circular(r(10)),
                            border: Border.all(color: AppColors.inputBorder),
                          ),
                          child: Text(
                            digit,
                            style: GoogleFonts.montserrat(
                              fontSize: r(18),
                              fontWeight: FontWeight.w800,
                              color: AppColors.brandBlueDark,
                            ),
                          ),
                        ),
                      ),
                ],
              ),
              SizedBox(height: r(6)),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  pinLabel,
                  style: GoogleFonts.montserrat(
                    fontSize: r(11),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              SizedBox(height: r(14)),
            ],
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: r(16), vertical: r(18)),
              decoration: BoxDecoration(
                color: isCancelled
                    ? AppColors.error.withValues(alpha: 0.08)
                    : AppColors.infoBg,
                borderRadius: BorderRadius.circular(r(22)),
                border: Border.all(
                  color: isCancelled
                      ? AppColors.error.withValues(alpha: 0.2)
                      : AppColors.infoBorder,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        smartInfoMessage,
                        key: ValueKey(smartInfoMessage),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: r(14),
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: r(12)),
                  Icon(
                    isCancelled
                        ? Icons.cancel_outlined
                        : isDelivered
                        ? Icons.check_circle_outline_rounded
                        : Icons.delivery_dining_rounded,
                    color: isCancelled
                        ? AppColors.error
                        : AppColors.brandBlueDark,
                    size: r(32),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecenterButton extends StatelessWidget {
  final VoidCallback onTap;

  const _RecenterButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Positioned(
      right: r(16),
      bottom: r(16),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: r(48),
          height: r(48),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(r(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.my_location_rounded,
            color: AppColors.brandBlueDark,
            size: r(24),
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(r(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: r(42),
              color: AppColors.error,
            ),
            SizedBox(height: r(14)),
            Text(
              'Could not load order',
              style: GoogleFonts.montserrat(
                fontSize: r(18),
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: r(8)),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: r(12),
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: r(18)),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
