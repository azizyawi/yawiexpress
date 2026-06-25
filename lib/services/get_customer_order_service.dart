import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wanmac/config/api_config.dart';
import 'package:wanmac/models/order_model.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class OrderApiService {
  /// =========================
  /// REST: Initial Fetch
  /// =========================
 static Future<List<OrderModel>> getCustomerOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';

    if (userId.isEmpty) {
      return [];
    }

    final uri = Uri.parse('${ApiConfig.ordersBaseUrl}/orders?userId=$userId');

    final response = await http
        .get(uri, headers: {'Content-Type': 'application/json'})
        .timeout(const Duration(seconds: 25));

    final decoded = response.body.isNotEmpty
        ? jsonDecode(response.body)
        : <String, dynamic>{};

    if (response.statusCode == 200) {
      final data = decoded['data'];

      if (data == null) return [];

      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map((item) => OrderModel.fromJson(item))
            .toList();
      }

      return [];
    }

    if (response.statusCode == 404) {
      return [];
    }

    throw Exception(decoded['message'] ?? 'Failed to fetch orders');
  }
  /// =========================
  /// WebSocket: Realtime
  /// =========================

  static Future<WebSocketChannel> connectToOrderUpdates() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';

    if (userId.isEmpty) {
      throw Exception('No userId found for WebSocket');
    }

    final channel = WebSocketChannel.connect(Uri.parse(ApiConfig.wsUrl));

    // Subscribe after connection
    channel.sink.add(jsonEncode({"action": "subscribe", "userId": userId}));

    return channel;
  }
}
