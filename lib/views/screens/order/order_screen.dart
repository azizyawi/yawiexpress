import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:wanmac/core/theme/app_colors.dart' show AppColors;
import 'package:wanmac/core/utils/app_snackbar.dart';
import 'package:wanmac/models/order_model.dart';
import 'package:wanmac/services/get_customer_order_service.dart';
import 'package:wanmac/services/order_api_service.dart' as tracking_service;
import 'package:wanmac/views/screens/OrderTrackingScreen/order_tracking_screen.dart';

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

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  int selectedTab = 0;
  final List<String> tabs = ['Pending', 'Ongoing', 'Completed'];

  List<OrderModel> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;

  WebSocketChannel? _channel;
  StreamSubscription? _socketSubscription;

  @override
  void initState() {
    super.initState();
    _initializeOrders();
  }

  Future<void> _initializeOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final orders = await OrderApiService.getCustomerOrders();

      if (!mounted) return;

      setState(() {
        _orders = orders;
        _sortOrders();
        _isLoading = false;
        _errorMessage = null;
      });

      unawaited(_connectSocket());
    } catch (e) {
      debugPrint('Initial orders load failed: $e');

      if (!mounted) return;

      setState(() {
        _orders = [];
        _isLoading = false;
        _errorMessage = null;
      });

      unawaited(_connectSocket());
    }
  }

  Future<void> _connectSocket() async {
    try {
      await _socketSubscription?.cancel();
      await _channel?.sink.close();

      _channel = await OrderApiService.connectToOrderUpdates();

      _socketSubscription = _channel!.stream.listen((event) {
        try {
          final decoded = jsonDecode(event);

          if (!mounted) return;

          setState(() {
            if (decoded is Map<String, dynamic>) {
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
            }

            _sortOrders();
          });
        } catch (e) {
          debugPrint('Socket message parse error: $e');
        }
      });
    } catch (e) {
      debugPrint('WebSocket connection failed: $e');
    }
  }

  void _sortOrders() {
    _orders.sort((a, b) {
      final aDate = a.timestamps.createdAt;
      final bDate = b.timestamps.createdAt;
      return bDate.compareTo(aDate);
    });
  }

  Future<void> _refreshOrders() async {
    HapticFeedback.selectionClick();

    try {
      final orders = await OrderApiService.getCustomerOrders();

      if (!mounted) return;

      setState(() {
        _orders = orders;
        _sortOrders();
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            "We could not load your orders right now. Please try again.";
      });
    }
  }

  Future<void> _copyCode(String code, String message) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;

    HapticFeedback.lightImpact();
    AppSnackBar.show(context, message: message, type: AppSnackBarType.success);
  }

  void _openTracking(OrderModel order) {
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
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orders = _filteredOrders(_orders);
    final maxWidth = _maxContentWidth(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            children: [
              _OrdersArtHeader(
                selectedTab: selectedTab,
                tabs: tabs,
                pendingCount: _orders.where(_isPendingOrder).length,
                ongoingCount: _orders.where(_isOngoingOrder).length,
                completedCount: _orders.where(_isCompletedOrder).length,
                onTabChanged: (index) {
                  HapticFeedback.selectionClick();
                  setState(() => selectedTab = index);
                },
              ),
              Expanded(child: _buildBody(orders)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(List<OrderModel> orders) {
    final s = _scale(context);
    double r(double value) => value * s;

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: r(30),
              height: r(30),
              child: const CircularProgressIndicator(
                strokeWidth: 2.6,
                color: AppColors.brandBlueDark,
              ),
            ),
            SizedBox(height: r(14)),
            Text(
              'Loading orders',
              style: _T.text(
                context,
                12.5,
                FontWeight.w600,
                AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null && _orders.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(r(20)),
        child: _EmptyStateCard(
          icon: Icons.wifi_off_rounded,
          title: 'Could not load orders',
          subtitle: _errorMessage!,
          buttonText: 'Try again',
          onPressed: _initializeOrders,
        ),
      );
    }

    if (orders.isEmpty) {
      return RefreshIndicator(
        color: AppColors.brandBlueDark,
        onRefresh: _refreshOrders,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(r(20), r(44), r(20), r(28)),
          children: [
            _EmptyStateCard(
              icon: Icons.inventory_2_outlined,
              title: 'No ${tabs[selectedTab].toLowerCase()} orders',
              subtitle:
                  'Orders in this stage will appear here as soon as they are available.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.brandBlueDark,
      onRefresh: _refreshOrders,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(r(20), r(12), r(20), r(28)),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];

          return Padding(
            padding: EdgeInsets.only(bottom: r(14)),
            child: _OrderCard(
              order: order,
              pickup: _safeName(
                order.pickup.address,
                fallback: 'Pickup location',
              ),
              dropoff: _safeName(
                order.delivery.address,
                fallback: 'Dropoff location',
              ),
              amount: '₦${_formatAmount(order.pricing.amount)}',
              date: _formatDate(order.timestamps.createdAt),
              statusLabel: _statusLabel(order.status),
              statusColor: _statusColor(order.status),
              progressText: _progressText(order),
              progressIndex: _progressIndex(order),
              isCompleted: _isCompletedOrder(order),
              onTrack: () => _openTracking(order),
              onCopyCode: _copyCode,
            ),
          );
        },
      ),
    );
  }

  List<OrderModel> _filteredOrders(List<OrderModel> orders) {
    switch (selectedTab) {
      case 0:
        return orders.where(_isPendingOrder).toList();
      case 1:
        return orders.where(_isOngoingOrder).toList();
      case 2:
        return orders.where(_isCompletedOrder).toList();
      default:
        return orders;
    }
  }

  bool _isPendingOrder(OrderModel order) {
    return order.status == 'pending_payment' ||
        order.status == 'pending' ||
        order.status == 'accepted';
  }

  bool _isOngoingOrder(OrderModel order) {
    return order.status == 'arrived_pickup' ||
        order.status == 'picked_up' ||
        order.status == 'arrived_delivery';
  }

  bool _isCompletedOrder(OrderModel order) {
    return order.status == 'delivered' || order.status == 'cancelled';
  }

  int _progressIndex(OrderModel order) {
    switch (order.status) {
      case 'pending_payment':
      case 'pending':
        return 0;
      case 'accepted':
      case 'arrived_pickup':
        return 1;
      case 'picked_up':
        return 2;
      case 'arrived_delivery':
        return 3;
      case 'delivered':
        return 4;
      case 'cancelled':
        return 0;
      default:
        return 0;
    }
  }

  String _progressText(OrderModel order) {
    final time = _formatTime(order.timestamps.createdAt);

    switch (order.status) {
      case 'pending_payment':
        return '$time • Awaiting payment';
      case 'pending':
        return '$time • Order received';
      case 'accepted':
        return '$time • Rider assigned';
      case 'arrived_pickup':
        return '$time • Rider at pickup';
      case 'picked_up':
        return '$time • Package in transit';
      case 'arrived_delivery':
        return '$time • Rider at destination';
      case 'delivered':
        return '$time • Delivered';
      case 'cancelled':
        return '$time • Cancelled';
      default:
        return '$time • Updated';
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending_payment':
        return 'Awaiting payment';
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'arrived_pickup':
        return 'At pickup';
      case 'picked_up':
        return 'In transit';
      case 'arrived_delivery':
        return 'At destination';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Updated';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending_payment':
      case 'pending':
        return const Color(0xFFB7791F);
      case 'accepted':
      case 'arrived_pickup':
      case 'picked_up':
      case 'arrived_delivery':
        return AppColors.brandBlueDark;
      case 'delivered':
        return const Color(0xFF15803D);
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatTime(String isoString) {
    if (isoString.isEmpty) return '--:--';

    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      final hour = dateTime.hour == 0
          ? 12
          : dateTime.hour > 12
          ? dateTime.hour - 12
          : dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = dateTime.hour >= 12 ? 'pm' : 'am';
      return '$hour:$minute $period';
    } catch (_) {
      return '--:--';
    }
  }

  String _formatDate(String isoString) {
    if (isoString.isEmpty) return '--';

    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (_) {
      return '--';
    }
  }

  String _formatAmount(double amount) {
    final value = amount.toStringAsFixed(0);
    final chars = value.split('').reversed.toList();
    final buffer = StringBuffer();

    for (int i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) buffer.write(',');
      buffer.write(chars[i]);
    }

    return buffer.toString().split('').reversed.join();
  }

  String _safeName(String? value, {required String fallback}) {
    if (value == null || value.trim().isEmpty) return fallback;
    return value.trim();
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final String pickup;
  final String dropoff;
  final String amount;
  final String date;
  final String statusLabel;
  final Color statusColor;
  final String progressText;
  final int progressIndex;
  final bool isCompleted;
  final VoidCallback onTrack;
  final Future<void> Function(String code, String message) onCopyCode;

  const _OrderCard({
    required this.order,
    required this.pickup,
    required this.dropoff,
    required this.amount,
    required this.date,
    required this.statusLabel,
    required this.statusColor,
    required this.progressText,
    required this.progressIndex,
    required this.isCompleted,
    required this.onTrack,
    required this.onCopyCode,
  });

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Container(
      padding: EdgeInsets.all(r(16)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(r(24)),
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
          _top(context),
          SizedBox(height: r(16)),
          _route(context),
          SizedBox(height: r(14)),
          _statusArea(context),
          SizedBox(height: r(14)),
          _progress(context),
          SizedBox(height: r(16)),
          _action(context),
        ],
      ),
    );
  }

  Widget _top(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: r(8),
                    height: r(8),
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: r(8)),
                  Flexible(
                    child: Text(
                      statusLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _T.text(
                        context,
                        14,
                        FontWeight.w800,
                        AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: r(6)),
              Text(
                progressText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _T.text(
                  context,
                  11.5,
                  FontWeight.w500,
                  AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: r(12)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              amount,
              style: _T.text(
                context,
                17,
                FontWeight.w800,
                AppColors.textPrimary,
              ),
            ),
            SizedBox(height: r(5)),
            GestureDetector(
              onTap: () => onCopyCode(order.orderId, 'Order ID copied'),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: r(10),
                  vertical: r(6),
                ),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(r(10)),
                  border: Border.all(color: AppColors.inputBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '#${_shortOrderId(order.orderId)}',
                      style: _T.text(
                        context,
                        10,
                        FontWeight.w700,
                        AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(width: r(6)),
                    Icon(
                      Icons.copy_rounded,
                      size: r(14),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: r(4)),
            Text(
              date,
              style: _T.text(
                context,
                10.8,
                FontWeight.w500,
                AppColors.textHint,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _shortOrderId(String id) {
    final clean = id.trim();
    if (clean.isEmpty) return 'ORDER';
    if (clean.length <= 10) return clean.toUpperCase();
    return clean.substring(0, 10).toUpperCase();
  }

  Widget _route(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Container(
      padding: EdgeInsets.all(r(14)),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(r(20)),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        children: [
          _routeRow(
            context,
            label: 'Pickup',
            value: pickup,
            dotColor: AppColors.brandBlueDark,
          ),
          Padding(
            padding: EdgeInsets.only(left: r(5.5)),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin: EdgeInsets.symmetric(vertical: r(6)),
                height: r(20),
                width: r(1.2),
                color: AppColors.inputBorder,
              ),
            ),
          ),
          _routeRow(
            context,
            label: 'Dropoff',
            value: dropoff,
            dotColor: AppColors.textPrimary,
          ),
        ],
      ),
    );
  }

  Widget _routeRow(
    BuildContext context, {
    required String label,
    required String value,
    required Color dotColor,
  }) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: r(11),
          height: r(11),
          margin: EdgeInsets.only(top: r(3)),
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        SizedBox(width: r(12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: _T.text(
                  context,
                  10.5,
                  FontWeight.w700,
                  AppColors.textHint,
                ),
              ),
              SizedBox(height: r(3)),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _T.text(
                  context,
                  13.8,
                  FontWeight.w700,
                  AppColors.textPrimary,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusArea(BuildContext context) {
    if (isCompleted) {
      return _messageBox(
        context,
        title: order.status == 'cancelled'
            ? 'This order was cancelled'
            : 'Delivery completed successfully',
        subtitle: order.status == 'cancelled'
            ? 'No further action is required.'
            : 'Your package has reached its destination.',
        icon: order.status == 'cancelled'
            ? Icons.cancel_rounded
            : Icons.check_circle_rounded,
        color: order.status == 'cancelled'
            ? AppColors.error
            : const Color(0xFF15803D),
      );
    }

    final showPickupCode =
        order.status == 'accepted' || order.status == 'arrived_pickup';

    final showDeliveryCode =
        order.status == 'picked_up' || order.status == 'arrived_delivery';

    if (showPickupCode || showDeliveryCode) {
      final code = showDeliveryCode
          ? order.pins.deliveryPin
          : order.pins.pickupPin;

      return _codeBox(
        context,
        code: code,
        title: showDeliveryCode ? 'Delivery code' : 'Pickup code',
        subtitle: showDeliveryCode
            ? 'Share this code with the receiver.'
            : 'Share this code with your rider.',
        message: showDeliveryCode
            ? 'Delivery code copied'
            : 'Pickup code copied',
      );
    }

    return _messageBox(
      context,
      title: order.status == 'pending_payment'
          ? 'Payment pending'
          : 'Preparing your order',
      subtitle: order.status == 'pending_payment'
          ? 'Complete payment to continue.'
          : 'Your verification code will appear when needed.',
      icon: Icons.hourglass_empty_rounded,
      color: AppColors.brandBlueDark,
    );
  }

  Widget _messageBox(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Container(
      padding: EdgeInsets.all(r(13)),
      decoration: BoxDecoration(
        color: color.withOpacity(.065),
        borderRadius: BorderRadius.circular(r(18)),
        border: Border.all(color: color.withOpacity(.10)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: r(20)),
          SizedBox(width: r(11)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: _T.text(
                    context,
                    12.8,
                    FontWeight.w700,
                    AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: r(3)),
                Text(
                  subtitle,
                  style: _T.text(
                    context,
                    11.2,
                    FontWeight.w500,
                    AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _codeBox(
    BuildContext context, {
    required String code,
    required String title,
    required String subtitle,
    required String message,
  }) {
    final s = _scale(context);
    double r(double value) => value * s;
    final safeCode = code.isEmpty ? '----' : code;

    return Container(
      padding: EdgeInsets.all(r(14)),
      decoration: BoxDecoration(
        color: AppColors.infoBg,
        borderRadius: BorderRadius.circular(r(18)),
        border: Border.all(color: AppColors.infoBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: _T.text(
                        context,
                        13.2,
                        FontWeight.w800,
                        AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: r(4)),
                    Text(
                      subtitle,
                      style: _T.text(
                        context,
                        11.3,
                        FontWeight.w500,
                        AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => onCopyCode(safeCode, message),
                child: Container(
                  padding: EdgeInsets.all(r(8)),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(r(12)),
                    border: Border.all(color: AppColors.infoBorder),
                  ),
                  child: Icon(
                    Icons.copy_rounded,
                    size: r(17),
                    color: AppColors.brandBlueDark,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: r(13)),
          Row(
            children: List.generate(safeCode.length, (index) {
              return Expanded(
                child: Container(
                  height: r(46),
                  margin: EdgeInsets.only(
                    right: index == safeCode.length - 1 ? 0 : r(7),
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(r(13)),
                    border: Border.all(color: AppColors.infoBorder),
                  ),
                  child: Text(
                    safeCode[index],
                    style: _T.text(
                      context,
                      17,
                      FontWeight.w800,
                      AppColors.brandBlueDark,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _progress(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Row(
      children: List.generate(5, (index) {
        final active = index <= progressIndex;

        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            height: r(5),
            margin: EdgeInsets.only(right: index == 4 ? 0 : r(6)),
            decoration: BoxDecoration(
              color: active ? AppColors.brandBlueDark : AppColors.inputBorder,
              borderRadius: BorderRadius.circular(r(100)),
            ),
          ),
        );
      }),
    );
  }

  Widget _action(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return SizedBox(
      width: double.infinity,
      height: r(49),
      child: ElevatedButton(
        onPressed: onTrack,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.brandBlueDark,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(r(15)),
          ),
        ),
        child: Text(
          isCompleted ? 'View delivery' : 'Track order',
          style: _T.text(context, 13, FontWeight.w800, Colors.white),
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonText;
  final VoidCallback? onPressed;

  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonText,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double value) => value * s;

    return Container(
      padding: EdgeInsets.all(r(26)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(r(24)),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        children: [
          Container(
            width: r(56),
            height: r(56),
            decoration: BoxDecoration(
              color: AppColors.infoBg,
              borderRadius: BorderRadius.circular(r(18)),
              border: Border.all(color: AppColors.infoBorder),
            ),
            child: Icon(icon, size: r(28), color: AppColors.brandBlueDark),
          ),
          SizedBox(height: r(16)),
          Text(
            title,
            textAlign: TextAlign.center,
            style: _T.text(context, 17, FontWeight.w800, AppColors.textPrimary),
          ),
          SizedBox(height: r(8)),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: _T.text(
              context,
              12.3,
              FontWeight.w500,
              AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          if (buttonText != null && onPressed != null) ...[
            SizedBox(height: r(20)),
            SizedBox(
              height: r(46),
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: AppColors.brandBlueDark,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: r(22)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(r(14)),
                  ),
                ),
                child: Text(
                  buttonText!,
                  style: _T.text(context, 12.5, FontWeight.w800, Colors.white),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _T {
  static TextStyle text(
    BuildContext context,
    double size,
    FontWeight weight,
    Color color, {
    double? height,
  }) {
    return GoogleFonts.montserrat(
      fontSize: size * _scale(context),
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: -0.08,
    );
  }
}

class _OrdersArtHeader extends StatelessWidget {
  final int selectedTab;
  final List<String> tabs;
  final int pendingCount;
  final int ongoingCount;
  final int completedCount;
  final ValueChanged<int> onTabChanged;

  const _OrdersArtHeader({
    required this.selectedTab,
    required this.tabs,
    required this.pendingCount,
    required this.ongoingCount,
    required this.completedCount,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    double r(double v) => v * s;

    final counts = [pendingCount, ongoingCount, completedCount];
    final total = pendingCount + ongoingCount + completedCount;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(r(20), r(18), r(20), r(20)),
      decoration: const BoxDecoration(color: AppColors.brandBlueDark),
      child: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: _OrdersTopArtPainter()),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Orders',
                          style: _T.text(
                            context,
                            29,
                            FontWeight.w800,
                            Colors.white,
                            height: 1,
                          ),
                        ),
                        SizedBox(height: r(7)),
                        Text(
                          '$total deliveries',
                          style: _T.text(
                            context,
                            13,
                            FontWeight.w500,
                            Colors.white.withOpacity(.72),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: r(11),
                      vertical: r(7),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.12),
                      borderRadius: BorderRadius.circular(r(999)),
                      border: Border.all(color: Colors.white.withOpacity(.18)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: r(6),
                          height: r(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: r(7)),
                        Text(
                          'Live',
                          style: _T.text(
                            context,
                            11.5,
                            FontWeight.w800,
                            Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: r(24)),

              Container(
                padding: EdgeInsets.all(r(4)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(r(17)),
                ),
                child: Row(
                  children: List.generate(tabs.length, (index) {
                    final isSelected = selectedTab == index;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => onTabChanged(index),
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: EdgeInsets.symmetric(vertical: r(11)),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.brandBlueDark
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(r(13)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  tabs[index],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _T.text(
                                    context,
                                    11.5,
                                    FontWeight.w800,
                                    isSelected ? Colors.white : AppColors.label,
                                  ),
                                ),
                              ),
                              SizedBox(width: r(6)),
                              Text(
                                counts[index].toString(),
                                style: _T.text(
                                  context,
                                  11.5,
                                  FontWeight.w800,
                                  isSelected
                                      ? Colors.white.withOpacity(.85)
                                      : AppColors.textHint,
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
          ),
        ],
      ),
    );
  }
}

class _OrdersTopArtPainter extends CustomPainter {
  const _OrdersTopArtPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.white.withOpacity(.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final soft = Paint()
      ..color = Colors.white.withOpacity(.055)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * .40, size.height * .55)
      ..cubicTo(
        size.width * .55,
        size.height * .30,
        size.width * .70,
        size.height * .72,
        size.width * .94,
        size.height * .42,
      );

    canvas.drawPath(path, soft);
    _drawDashed(canvas, path, line);

    _drawBox(canvas, Offset(size.width * .78, size.height * .25), line);
    _drawPin(canvas, Offset(size.width * .90, size.height * .62), line);
    _drawBike(canvas, Offset(size.width * .52, size.height * .78), line);

    final dot = Paint()..color = Colors.white.withOpacity(.16);
    canvas.drawCircle(Offset(size.width * .66, size.height * .32), 4, dot);
    canvas.drawCircle(Offset(size.width * .94, size.height * .28), 5, dot);
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + 9).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += 18;
      }
    }
  }

  void _drawBox(Canvas canvas, Offset c, Paint p) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c, width: 42, height: 34),
      const Radius.circular(7),
    );
    canvas.drawRRect(rect, p);
    canvas.drawLine(
      Offset(c.dx - 21, c.dy - 6),
      Offset(c.dx + 21, c.dy - 6),
      p,
    );
    canvas.drawLine(Offset(c.dx, c.dy - 17), Offset(c.dx, c.dy + 17), p);
  }

  void _drawPin(Canvas canvas, Offset c, Paint p) {
    final path = Path()
      ..moveTo(c.dx, c.dy + 16)
      ..cubicTo(c.dx - 14, c.dy, c.dx - 10, c.dy - 18, c.dx, c.dy - 18)
      ..cubicTo(c.dx + 10, c.dy - 18, c.dx + 14, c.dy, c.dx, c.dy + 16);
    canvas.drawPath(path, p);
    canvas.drawCircle(Offset(c.dx, c.dy - 5), 4, p);
  }

  void _drawBike(Canvas canvas, Offset c, Paint p) {
    canvas.drawCircle(c, 9, p);
    canvas.drawCircle(c.translate(40, 0), 9, p);
    canvas.drawLine(c, c.translate(18, -17), p);
    canvas.drawLine(c.translate(18, -17), c.translate(40, 0), p);
    canvas.drawLine(c.translate(18, -17), c.translate(33, -22), p);
    canvas.drawLine(c.translate(33, -22), c.translate(47, -16), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
