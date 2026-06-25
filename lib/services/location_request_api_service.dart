import 'dart:convert';

import 'package:http/http.dart' as http;

class LocationRequestApiService {
  final String baseUrl;

  const LocationRequestApiService({required this.baseUrl});

  Future<LocationRequestCreateResult> createLocationRequest() async {
    final response = await http.post(
      Uri.parse('$baseUrl/location-requests'),
      headers: {'Content-Type': 'application/json'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 201) {
      throw Exception(data['message'] ?? 'Failed to create location request');
    }

    return LocationRequestCreateResult(
      token: data['token']?.toString() ?? '',
      status: data['status']?.toString() ?? 'PENDING',
      link: data['link']?.toString() ?? '',
    );
  }

  Future<LocationRequestStatusResult> getLocationRequestStatus(
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/location-requests/$token'),
      headers: {'Content-Type': 'application/json'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to fetch location request');
    }

    return LocationRequestStatusResult(
      token: data['token']?.toString() ?? token,
      status: data['status']?.toString() ?? 'PENDING',
      confirmedAt: data['confirmedAt']?.toString(),
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      accuracy: (data['accuracy'] as num?)?.toDouble(),
      note: data['note']?.toString(),
    );
  }
}

class LocationRequestCreateResult {
  final String token;
  final String status;
  final String link;

  const LocationRequestCreateResult({
    required this.token,
    required this.status,
    required this.link,
  });
}

class LocationRequestStatusResult {
  final String token;
  final String status;
  final String? confirmedAt;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final String? note;

  const LocationRequestStatusResult({
    required this.token,
    required this.status,
    this.confirmedAt,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.note,
  });

  bool get isConfirmed =>
      status == 'CONFIRMED' && latitude != null && longitude != null;

  bool get isExpired => status == 'EXPIRED';
  bool get isPending => status == 'PENDING';
}
