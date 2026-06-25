import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wanmac/models/location_model.dart';

class AppLocationStorage {
  static const String _pickupLocationKey = 'pickup_location';

  static Future<void> savePickupLocation(LocationModel location) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _pickupLocationKey,
      jsonEncode({
        'latitude': location.latitude,
        'longitude': location.longitude,
        'address': location.address,
        'shortAddress': location.shortAddress,
        'city': location.city,
        'state': location.state,
        'country': location.country,
        'placeId': location.placeId,
      }),
    );
  }

  static Future<LocationModel?> getPickupLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pickupLocationKey);

    if (raw == null || raw.isEmpty) return null;

    final data = jsonDecode(raw) as Map<String, dynamic>;

    return LocationModel(
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      address: data['address']?.toString() ?? '',
      shortAddress: data['shortAddress']?.toString() ?? '',
      city: data['city']?.toString(),
      state: data['state']?.toString(),
      country: data['country']?.toString(),
      placeId: data['placeId']?.toString(),
    );
  }

  static Future<void> clearPickupLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pickupLocationKey);
  }
}
