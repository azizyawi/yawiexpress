import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:wanmac/config/api_config.dart';

class OrderApiService {
  const OrderApiService();

  String get baseUrl => ApiConfig.ordersBaseUrl;

  Future<Map<String, dynamic>> cancelOrder({required String orderId}) async {
    final url = Uri.parse('$baseUrl/orders/cancel');

    print('CANCEL ORDER URL: $url');
    print('CANCEL ORDER ID: $orderId');

    final response = await http.post(
      url,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'orderId': orderId}),
    );

    print('CANCEL ORDER STATUS: ${response.statusCode}');
    print('CANCEL ORDER RESPONSE: ${response.body}');

    final Map<String, dynamic> decoded =
        jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(decoded['message'] ?? 'Failed to cancel order');
    }

    return decoded;
  }

  Future<Map<String, dynamic>> createOrder({
    required Map<String, dynamic> payload,
  }) async {
    final url = Uri.parse('$baseUrl/orders');
    final body = jsonEncode(payload);

    final response = await http.post(
      url,
      headers: const {'Content-Type': 'application/json'},
      body: body,
    );

    final Map<String, dynamic> decoded =
        jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(decoded['message'] ?? 'Failed to create order');
    }

    return decoded;
  }

  Future<Map<String, dynamic>> validatePromo({
    required String code,
    required double pickupLat,
    required double pickupLng,
    required double deliveryLat,
    required double deliveryLng,
  }) async {
    final url = Uri.parse('$baseUrl/promos/validate');

    final payload = {
      'code': code,
      'pickup': {'lat': pickupLat, 'lng': pickupLng},
      'delivery': {'lat': deliveryLat, 'lng': deliveryLng},
    };

    final response = await http.post(
      url,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    final Map<String, dynamic> decoded =
        jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(decoded['message'] ?? 'Failed to validate promo');
    }

    return decoded;
  }

  Future<Map<String, dynamic>> getOrderById({required String orderId}) async {
    final url = Uri.parse('$baseUrl/orders/get-by-id');

    final response = await http.post(
      url,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'orderId': orderId}),
    );

    final Map<String, dynamic> decoded =
        jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(decoded['message'] ?? 'Failed to fetch order');
    }

    return decoded;
  }

  Future<Map<String, dynamic>> initializePayment({
    required String orderId,
  }) async {
    final url = Uri.parse('$baseUrl/orders/$orderId/pay');

    final response = await http.post(
      url,
      headers: const {'Content-Type': 'application/json'},
    );

    final Map<String, dynamic> decoded =
        jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(decoded['message'] ?? 'Failed to initialize payment');
    }

    return decoded;
  }

  Future<Map<String, dynamic>> verifyPayment({
    required String reference,
  }) async {
    final url = Uri.parse(
      '$baseUrl/payments/paystack/verify?reference=$reference',
    );

    final response = await http.get(
      url,
      headers: const {'Content-Type': 'application/json'},
    );

    final Map<String, dynamic> decoded =
        jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(decoded['message'] ?? 'Failed to verify payment');
    }

    return decoded;
  }
}
