import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wanmac/config/api_config.dart';
import 'package:wanmac/models/recent_activity_model.dart';

class RecentActivitiesService {
  Future<List<RecentActivityModel>> getRecentActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final idToken = prefs.getString('idToken') ?? '';
    final userId = prefs.getString('userId') ?? '';

    if (idToken.isEmpty) {
      throw Exception('User is not authenticated. No ID token found.');
    }

    if (userId.isEmpty) {
      throw Exception('User ID not found.');
    }

    final uri = Uri.parse(
      '${ApiConfig.ordersBaseUrl}/activities?userId=$userId',
    );

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final List<dynamic> activities = decoded['data'] ?? [];

      return activities
          .map((item) => RecentActivityModel.fromJson(item))
          .toList();
    }

    throw Exception(
      decoded['message']?.toString() ?? 'Failed to fetch recent activities',
    );
  }
}
