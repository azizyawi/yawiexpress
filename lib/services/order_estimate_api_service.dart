import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:wanmac/models/order_estimate_model.dart';

class OrderEstimateApiService {
  final String estimateUrl;

  // Persistent client avoids recreating TCP/TLS connections on every request
  static final http.Client _client = http.Client();

  const OrderEstimateApiService({required this.estimateUrl});

  Future<OrderEstimateModel> fetchEstimate({
    required double pickupLat,
    required double pickupLng,
    required double deliveryLat,
    required double deliveryLng,
  }) async {
    final uri = Uri.parse(estimateUrl);
    final payload = jsonEncode({
      'pickup': {'lat': pickupLat, 'lng': pickupLng},
      'delivery': {'lat': deliveryLat, 'lng': deliveryLng},
    });

    Exception? lastError;

    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        final response = await _client
            .post(
              uri,
              headers: const {
                'Content-Type': 'application/json',
                'Connection': 'keep-alive', // Hint for the server
              },
              body: payload,
            )
            .timeout(
              const Duration(seconds: 10),
            ); // Reduced from 20s to be snappier

        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;

        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw Exception(
            (data['message'] ?? 'Failed to fetch estimate').toString(),
          );
        }

        final result = data['data'];
        if (result is! Map<String, dynamic>) {
          throw Exception('Invalid estimate response');
        }

        return OrderEstimateModel.fromJson(result);
      } on TimeoutException {
        lastError = Exception('Estimate API timeout');
      } catch (e) {
        lastError = Exception('Estimate API network error: $e');
      }

      if (attempt < 3) {
        // Shorter retry delay (300ms, 600ms) for faster recovery
        await Future.delayed(Duration(milliseconds: 300 * attempt));
      }
    }

    throw lastError ?? Exception('Failed to fetch estimate');
  }
}
