import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:wanmac/core/theme/app_colors.dart';
import 'package:wanmac/models/order_model.dart';
import 'package:wanmac/models/recent_activity_model.dart';
import 'package:wanmac/services/get_customer_order_service.dart'
    as customer_orders;
import 'package:wanmac/services/order_api_service.dart' as tracking_service;
import 'package:wanmac/views/screens/OrderTrackingScreen/order_tracking_screen.dart';

class HomeActivityCard extends StatefulWidget {
  final Future<List<RecentActivityModel>> recentActivitiesFuture;

  const HomeActivityCard({super.key, required this.recentActivitiesFuture});

  @override
  State<HomeActivityCard> createState() => _HomeActivityCardState();
}

class _HomeActivityCardState extends State<HomeActivityCard> {
  List<OrderModel> _orders = [];

  WebSocketChannel? _channel;
  StreamSubscription? _socketSubscription;

  bool _isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).shortestSide >= 600;

  bool _isLandscape(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.landscape;

  bool _isShortHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height < 700;

  @override
  void initState() {
    super.initState();
    _initializeOrders();
  }

  Future<void> _initializeOrders() async {
    try {
      final orders = await customer_orders.OrderApiService.getCustomerOrders();

      if (!mounted) return;

      setState(() {
        _orders = orders;
        _sortOrders();
      });

      await _connectSocket();
    } catch (e) {
      debugPrint('Home orders load failed: $e');
    }
  }

Future<void> _connectSocket() async {
    try {
      await _socketSubscription?.cancel();
      _socketSubscription = null;

      await _channel?.sink.close();
      _channel = null;

      final channel =
          await customer_orders.OrderApiService.connectToOrderUpdates();

      if (!mounted) {
        await channel.sink.close();
        return;
      }

      _channel = channel;

      _socketSubscription = channel.stream.listen(
        (event) {
          try {
            final decoded = jsonDecode(event);

            if (!mounted || decoded is! Map<String, dynamic>) {
              return;
            }

            setState(() {
              if (decoded['type'] == 'ORDER_UPDATED' &&
                  decoded['data'] is Map<String, dynamic>) {
                final updatedOrder = OrderModel.fromJson(
                  decoded['data'] as Map<String, dynamic>,
                );

                final index = _orders.indexWhere(
                  (order) => order.orderId == updatedOrder.orderId,
                );

                if (index >= 0) {
                  _orders[index] = updatedOrder;
                } else {
                  _orders.insert(0, updatedOrder);
                }
              }

              if (decoded['type'] == 'ORDER_DELETED') {
                final orderId = decoded['orderId'];

                _orders.removeWhere((order) => order.orderId == orderId);
              }

              _sortOrders();
            });
          } catch (error) {
            debugPrint('Home socket message parse error: $error');
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('❌ Home WebSocket stream error: $error');
        },
        onDone: () {
          debugPrint(
            '🔌 Home WebSocket closed. '
            'Code: ${channel.closeCode}, '
            'Reason: ${channel.closeReason}',
          );
        },
        cancelOnError: false,
      );
    } catch (error, stackTrace) {
      debugPrint('❌ Home WebSocket connection failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _sortOrders() {
    _orders.sort(
      (a, b) => b.timestamps.createdAt.compareTo(a.timestamps.createdAt),
    );
  }

  List<OrderModel> get _activeOrders {
    final activeOrders = _orders.where((order) {
      return order.status == 'created' ||
          order.status == 'pending_payment' ||
          order.status == 'pending' ||
          order.status == 'accepted' ||
          order.status == 'arrived_pickup' ||
          order.status == 'picked_up' ||
          order.status == 'arrived_delivery';
    }).toList();

    activeOrders.sort(
      (a, b) => b.timestamps.createdAt.compareTo(a.timestamps.createdAt),
    );

    return activeOrders.take(2).toList();
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _channel?.sink.close();
    super.dispose();
  }

  Widget _emptyState(BuildContext context) {
    final isTablet = _isTablet(context);
    final isLandscape = _isLandscape(context);
    final isShort = _isShortHeight(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 28 : 22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.inputBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.025),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: isTablet ? 108 : (isLandscape || isShort ? 82 : 96),
            height: isTablet ? 108 : (isLandscape || isShort ? 82 : 96),
            padding: EdgeInsets.all(isTablet ? 20 : 18),
            decoration: BoxDecoration(
              color: AppColors.brandBlueDark.withOpacity(.06),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Image.asset(
              'assets/icons/cube.png',
              fit: BoxFit.contain,
              color: AppColors.brandBlueDark,
            ),
          ),
          SizedBox(height: isLandscape || isShort ? 16 : 22),
          Text(
            'No active deliveries yet',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Text(
              'Your deliveries will appear here once you place an order and a rider starts moving your package.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: isTablet ? 13.5 : 12.5,
                fontWeight: FontWeight.w500,
                height: 1.6,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          SizedBox(height: isLandscape || isShort ? 16 : 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.brandBlueDark.withOpacity(.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF16A34A),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Real-time delivery tracking',
                  style: GoogleFonts.montserrat(
                    fontSize: isTablet ? 12 : 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandBlueDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeOrders = _activeOrders;
    final isLandscape = _isLandscape(context);
    final spacing = isLandscape ? 12.0 : 14.0;

    if (activeOrders.isEmpty) return _emptyState(context);

    return Column(
      children: List.generate(activeOrders.length, (index) {
        final order = activeOrders[index];

        return Column(
          children: [
            _HomeLiveTrackingCard(
              order: order,
              liveIndex: index + 1,
              totalLiveCount: activeOrders.length,
            ),
            if (index != activeOrders.length - 1) SizedBox(height: spacing),
          ],
        );
      }),
    );
  }
}

class _HomeLiveTrackingCard extends StatelessWidget {
  final OrderModel order;
  final int liveIndex;
  final int totalLiveCount;

  const _HomeLiveTrackingCard({
    required this.order,
    required this.liveIndex,
    required this.totalLiveCount,
  });

  static const Color _softBlue = Color(0xFFEAF2FF);
  static const Color _deepBlue = Color(0xFF123B7A);
  static const Color _cleanBorder = Color(0xFFE6EAF0);
  static const Color _softGreen = Color(0xFFEAF8F1);
  static const Color _green = Color(0xFF138A5B);

  bool _isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).shortestSide >= 600;

  bool _isLandscape(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.landscape;

  bool _isShortHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height < 700;

  @override
  Widget build(BuildContext context) {
    final isTablet = _isTablet(context);
    final isLandscape = _isLandscape(context);
    final isShort = _isShortHeight(context);

    final statusText = _statusText(order.status);
    final progressText = _progressText(order.status);
    final progressValue = _progressValue(order.status);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderTrackingScreen(
              orderId: order.orderId,
              orderApiService: const tracking_service.OrderApiService(),
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isTablet ? 22 : 18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _cleanBorder),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withOpacity(0.035),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _topRow(context, statusText),
            SizedBox(height: isLandscape || isShort ? 12 : 16),
            Text(
              progressText,
              style: GoogleFonts.montserrat(
                fontSize: isTablet ? 13 : 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            SizedBox(height: isLandscape || isShort ? 10 : 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: progressValue,
                minHeight: isTablet ? 6 : 5.5,
                backgroundColor: AppColors.inputBorder.withOpacity(0.65),
                valueColor: const AlwaysStoppedAnimation<Color>(_deepBlue),
              ),
            ),
            SizedBox(height: isLandscape || isShort ? 12 : 16),
            Container(
              padding: EdgeInsets.all(isTablet ? 16 : 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFBFD),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _cleanBorder),
              ),
              child: Column(
                children: [
                  _routeRow(
                    context: context,
                    icon: Icons.radio_button_checked_rounded,
                    label: 'Pickup',
                    value: order.pickup.address,
                    iconColor: _green,
                  ),
                  SizedBox(height: isLandscape || isShort ? 8 : 10),
                  _routeRow(
                    context: context,
                    icon: Icons.location_on_rounded,
                    label: 'Dropoff',
                    value: order.delivery.address,
                    iconColor: _deepBlue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topRow(BuildContext context, String statusText) {
    final isTablet = _isTablet(context);

    return Row(
      children: [
        Container(
          width: isTablet ? 50 : 44,
          height: isTablet ? 50 : 44,
          decoration: BoxDecoration(
            color: _softBlue,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 9 : 8),
            child: Image.asset(
              'assets/images/wanmac_bike.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                totalLiveCount > 1
                    ? 'Live delivery $liveIndex'
                    : 'Live delivery',
                style: GoogleFonts.montserrat(
                  fontSize: isTablet ? 12 : 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                statusText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  fontSize: isTablet ? 15.5 : 14.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 13 : 12,
            vertical: isTablet ? 8 : 7,
          ),
          decoration: BoxDecoration(
            color: _softGreen,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Track',
                style: GoogleFonts.montserrat(
                  fontSize: isTablet ? 11.5 : 11,
                  fontWeight: FontWeight.w700,
                  color: _green,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_rounded,
                color: _green,
                size: isTablet ? 16 : 15,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _routeRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    final isTablet = _isTablet(context);

    return Row(
      children: [
        Icon(icon, color: iconColor, size: isTablet ? 18 : 17),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value.trim().isEmpty ? label : value.trim(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              fontSize: isTablet ? 13 : 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  String _statusText(String status) {
    switch (status) {
      case 'created':
      case 'pending_payment':
      case 'pending':
        return 'Finding rider';
      case 'accepted':
      case 'arrived_pickup':
        return 'Heading to pickup';
      case 'picked_up':
      case 'arrived_delivery':
        return 'In transit';
      default:
        return 'In progress';
    }
  }

  String _progressText(String status) {
    switch (status) {
      case 'created':
      case 'pending_payment':
      case 'pending':
        return 'We are finding a nearby rider for your delivery.';
      case 'accepted':
      case 'arrived_pickup':
        return 'Your rider is moving toward the pickup location.';
      case 'picked_up':
      case 'arrived_delivery':
        return 'Your package is moving toward the receiver.';
      default:
        return 'Track your delivery in real time.';
    }
  }

  double _progressValue(String status) {
    switch (status) {
      case 'created':
      case 'pending_payment':
      case 'pending':
        return 0.20;
      case 'accepted':
      case 'arrived_pickup':
        return 0.50;
      case 'picked_up':
      case 'arrived_delivery':
        return 0.80;
      default:
        return 0.30;
    }
  }
}
