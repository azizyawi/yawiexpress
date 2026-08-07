import 'dart:async';
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart' as loc;

import '../config/google_places_config.dart';
import '../models/location_model.dart';
import '../models/location_suggestion_model.dart';

class LocationService {
  // Center of Benin City
  static const double _beninLat = 6.3350;
  static const double _beninLng = 5.6037;

  static const String _googleHost = 'maps.googleapis.com';

  // Wider Benin City service area
  static const double _minBeninLat = 6.15;
  static const double _maxBeninLat = 6.50;
  static const double _minBeninLng = 5.40;
  static const double _maxBeninLng = 5.85;

  static const int _freshLocationMaxAgeSeconds = 30;

  StreamSubscription<Position>? _liveLocationSubscription;

  Future<void> _ensureLocationReady() async {
    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Location permissions are denied');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permissions are permanently denied.',
      );
    }

    final location = loc.Location();

    bool serviceEnabled = await location.serviceEnabled();

    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();

      if (serviceEnabled) {
        await Future.delayed(
          const Duration(seconds: 2),
        );
      }
    }

    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }
  }

  bool _isWithinBeninCityArea(
    double lat,
    double lng,
  ) {
    return lat >= _minBeninLat &&
        lat <= _maxBeninLat &&
        lng >= _minBeninLng &&
        lng <= _maxBeninLng;
  }

  Future<Position> getCurrentCoordinates() async {
    await _ensureLocationReady();

    final Position? lastKnown =
        await Geolocator.getLastKnownPosition();

    if (lastKnown != null) {
      final age = DateTime.now()
          .difference(lastKnown.timestamp)
          .inSeconds;

      if (age < _freshLocationMaxAgeSeconds &&
          _isWithinBeninCityArea(
            lastKnown.latitude,
            lastKnown.longitude,
          )) {
        return lastKnown;
      }
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );
    }
  }

  Future<LocationModel> getCurrentLocation({
    bool preferExactAddress = false,
  }) async {
    final position = await getCurrentCoordinates();

    return reverseGeocode(
      latitude: position.latitude,
      longitude: position.longitude,
      preferExactAddress: preferExactAddress,
    );
  }

  Future<LocationModel> reverseGeocode({
    required double latitude,
    required double longitude,
    bool preferExactAddress = false,
  }) async {
    final uri = Uri.https(
      _googleHost,
      '/maps/api/geocode/json',
      {
        'latlng': '$latitude,$longitude',
        'key': GooglePlacesConfig.apiKey,
      },
    );

    final response = await http
        .get(uri)
        .timeout(
          const Duration(seconds: 10),
        );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch address');
    }

    final data = jsonDecode(response.body);

    final results = data['results'] as List;

    if (data['status'] != 'OK' || results.isEmpty) {
      return LocationModel(
        latitude: latitude,
        longitude: longitude,
        address: '$latitude, $longitude',
        shortAddress: 'Pinned Location',
      );
    }

    var bestResult = results.firstWhere(
      (res) {
        final address =
            res['formatted_address']
                .toString()
                .toLowerCase();

        return !address.contains('unnamed') &&
            !address.contains('+');
      },
      orElse: () => results.first,
    );

    if (preferExactAddress) {
      final streetAddress = results.firstWhere(
        (res) {
          final types = res['types'] as List;

          return types.contains(
            'street_address',
          );
        },
        orElse: () => bestResult,
      );

      bestResult = streetAddress;
    }

    final String fullAddress =
        bestResult['formatted_address'];

    String? city;
    String? state;
    String? country;

    final components =
        bestResult['address_components'] as List;

    for (final comp in components) {
      final types =
          List<String>.from(comp['types']);

      if (types.contains('locality')) {
        city = comp['long_name'];
      }

      if (types.contains(
        'administrative_area_level_1',
      )) {
        state = comp['long_name'];
      }

      if (types.contains('country')) {
        country = comp['long_name'];
      }
    }

    return LocationModel(
      latitude: latitude,
      longitude: longitude,
      address: fullAddress,
      shortAddress: fullAddress.split(',').first,
      city: city ?? 'Benin City',
      state: state ?? 'Edo',
      country: country ?? 'Nigeria',
    );
  }

  /// Search addresses around Benin City.
  ///
  /// 30km gives wide Benin coverage without extending the
  /// autocomplete search unnecessarily far outside the city.
  Future<List<LocationSuggestionModel>> searchAddresses(
    String query,
  ) async {
    final cleanQuery = query.trim();

    if (cleanQuery.isEmpty) {
      return [];
    }

    final uri = Uri.https(
      _googleHost,
      '/maps/api/place/autocomplete/json',
      {
        'input': cleanQuery,
        'key': GooglePlacesConfig.apiKey,

        // Nigeria only
        'components': 'country:ng',

        // Center of Benin City
        'location': '$_beninLat,$_beninLng',

        // 30km around Benin
        'radius': '30000',

        // Do not allow autocomplete outside this area
        'strictbounds': 'true',
      },
    );

    try {
      final response = await http
          .get(uri)
          .timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode != 200) {
        return [];
      }

      final data = jsonDecode(response.body);

      final status = data['status'];

      if (status != 'OK' &&
          status != 'ZERO_RESULTS') {
        return [];
      }

      final predictions =
          data['predictions'] as List? ?? [];

      return predictions.map((item) {
        final structured =
            item['structured_formatting'] ?? {};

        return LocationSuggestionModel(
          placeId: item['place_id'] ?? '',
          title: structured['main_text'] ?? '',
          subtitle:
              structured['secondary_text'] ?? '',
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<LocationModel> getPlaceDetails(
    String placeId,
  ) async {
    final uri = Uri.https(
      _googleHost,
      '/maps/api/place/details/json',
      {
        'place_id': placeId,
        'fields':
            'formatted_address,name,geometry,address_component',
        'key': GooglePlacesConfig.apiKey,
      },
    );

    final response = await http
        .get(uri)
        .timeout(
          const Duration(seconds: 10),
        );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch place');
    }

    final data = jsonDecode(response.body);

    if (data['status'] != 'OK') {
      throw Exception('Place not found');
    }

    final result = data['result'];

    final location =
        result['geometry']['location'];

    return LocationModel(
      latitude:
          (location['lat'] as num).toDouble(),
      longitude:
          (location['lng'] as num).toDouble(),
      address:
          result['formatted_address'] ?? '',
      shortAddress:
          result['name'] ?? '',
    );
  }

  void startLiveTracking(
    void Function(Position position) onUpdate,
  ) {
    _liveLocationSubscription?.cancel();

    _liveLocationSubscription =
        Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy:
            LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    ).listen(onUpdate);
  }

  Future<void> stopLiveTracking() async {
    await _liveLocationSubscription?.cancel();
    _liveLocationSubscription = null;
  }

  Future<RouteResult> getRouteDistanceAndDuration({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
  }) async {
    final uri = Uri.parse(
      'https://routes.googleapis.com/directions/v2:computeRoutes',
    );

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key':
            GooglePlacesConfig.apiKey,
        'X-Goog-FieldMask':
            'routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline',
      },
      body: jsonEncode({
        'origin': {
          'location': {
            'latLng': {
              'latitude': originLat,
              'longitude': originLng,
            },
          },
        },
        'destination': {
          'location': {
            'latLng': {
              'latitude': destinationLat,
              'longitude': destinationLng,
            },
          },
        },
        'travelMode': 'DRIVE',
        'routingPreference': 'TRAFFIC_AWARE',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to calculate route',
      );
    }

    final data = jsonDecode(response.body);

    final routes = data['routes'] as List?;

    if (routes == null || routes.isEmpty) {
      throw Exception('No route found');
    }

    final route = routes.first;

    return RouteResult(
      distanceMeters:
          (route['distanceMeters'] as num)
              .toDouble(),
      durationText:
          route['duration'] ?? '0s',
      encodedPolyline:
          route['polyline']
                  ?['encodedPolyline'] ??
              '',
    );
  }
}

class RouteResult {
  final double distanceMeters;
  final String durationText;
  final String encodedPolyline;

  const RouteResult({
    required this.distanceMeters,
    required this.durationText,
    required this.encodedPolyline,
  });

  double get distanceKm =>
      distanceMeters / 1000;
}