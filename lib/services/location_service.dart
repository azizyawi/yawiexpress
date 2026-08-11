import 'dart:async';
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart' as loc;

import '../config/google_places_config.dart';
import '../models/location_model.dart';
import '../models/location_suggestion_model.dart';

enum LocationServiceErrorType {
  network,
  api,
  placeNotFound,
  outsideServiceArea,
  locationPermissionDenied,
  locationPermissionDeniedForever,
  locationServiceDisabled,
  routeNotFound,
}

class LocationServiceException implements Exception {
  final LocationServiceErrorType type;
  final String message;

  const LocationServiceException({
    required this.type,
    required this.message,
  });

  @override
  String toString() => message;
}

class LocationService {
  final http.Client _client = http.Client();

  // -------------------------------------------------------
  // WANPADI BACKEND
  // -------------------------------------------------------

  static const String _backendHost = 'estimate.wanmac.ng';

  // -------------------------------------------------------
  // BENIN CITY CONFIG
  // -------------------------------------------------------

  static const double _minBeninLat = 6.15;
  static const double _maxBeninLat = 6.50;
  static const double _minBeninLng = 5.40;
  static const double _maxBeninLng = 5.85;

  static const int _freshLocationMaxAgeSeconds = 30;

  static const Duration _getTimeout = Duration(
    seconds: 8,
  );

  static const Duration _postTimeout = Duration(
    seconds: 12,
  );

  static const int _defaultRetries = 2;

  StreamSubscription<Position>? _liveLocationSubscription;

  // -------------------------------------------------------
  // LOCATION PERMISSION
  // -------------------------------------------------------

  Future<void> _ensureLocationReady() async {
    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationServiceException(
        type:
            LocationServiceErrorType.locationPermissionDenied,
        message: 'Location permission is required.',
      );
    }

    if (permission ==
        LocationPermission.deniedForever) {
      throw const LocationServiceException(
        type: LocationServiceErrorType
            .locationPermissionDeniedForever,
        message:
            'Location permission is permanently denied.',
      );
    }

    final location = loc.Location();

    bool serviceEnabled =
        await location.serviceEnabled();

    if (!serviceEnabled) {
      serviceEnabled =
          await location.requestService();

      if (serviceEnabled) {
        await Future.delayed(
          const Duration(seconds: 2),
        );
      }
    }

    if (!serviceEnabled) {
      throw const LocationServiceException(
        type:
            LocationServiceErrorType.locationServiceDisabled,
        message: 'Location services are disabled.',
      );
    }
  }

  // -------------------------------------------------------
  // SERVICE AREA
  // -------------------------------------------------------

  bool _isWithinBeninCityArea(
    double latitude,
    double longitude,
  ) {
    return latitude >= _minBeninLat &&
        latitude <= _maxBeninLat &&
        longitude >= _minBeninLng &&
        longitude <= _maxBeninLng;
  }

  bool isWithinServiceArea(
    double latitude,
    double longitude,
  ) {
    return _isWithinBeninCityArea(
      latitude,
      longitude,
    );
  }

  // -------------------------------------------------------
  // NETWORK RETRY
  // -------------------------------------------------------

  bool _shouldRetryStatus(int statusCode) {
    return statusCode == 408 ||
        statusCode == 429 ||
        statusCode >= 500;
  }

  Duration _retryDelay(int attempt) {
    switch (attempt) {
      case 0:
        return const Duration(
          milliseconds: 450,
        );

      case 1:
        return const Duration(
          milliseconds: 900,
        );

      default:
        return const Duration(
          milliseconds: 1400,
        );
    }
  }

  Future<http.Response> _getWithRetry(
    Uri uri, {
    int retries = _defaultRetries,
  }) async {
    for (int attempt = 0;
        attempt <= retries;
        attempt++) {
      try {
        final response =
            await _client.get(uri).timeout(
                  _getTimeout,
                );

        if (!_shouldRetryStatus(
          response.statusCode,
        )) {
          return response;
        }

        if (attempt == retries) {
          return response;
        }
      } on TimeoutException {
        if (attempt == retries) {
          break;
        }
      } on http.ClientException {
        if (attempt == retries) {
          break;
        }
      } catch (_) {
        if (attempt == retries) {
          break;
        }
      }

      await Future.delayed(
        _retryDelay(attempt),
      );
    }

    throw const LocationServiceException(
      type: LocationServiceErrorType.network,
      message:
          'Unable to connect. Please check your internet connection.',
    );
  }

  Future<http.Response> _postAutocompleteWithRetry(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    const int retries = 1;

    for (int attempt = 0;
        attempt <= retries;
        attempt++) {
      try {
        final response = await _client
            .post(
              uri,
              headers: headers,
              body: body,
            )
            .timeout(
              const Duration(seconds: 5),
            );

        if (!_shouldRetryStatus(
          response.statusCode,
        )) {
          return response;
        }

        if (attempt == retries) {
          return response;
        }
      } on TimeoutException {
        if (attempt == retries) {
          break;
        }
      } on http.ClientException {
        if (attempt == retries) {
          break;
        }
      } catch (_) {
        if (attempt == retries) {
          break;
        }
      }

      await Future.delayed(
        const Duration(milliseconds: 350),
      );
    }

    throw const LocationServiceException(
      type: LocationServiceErrorType.network,
      message:
          'Having trouble loading locations. Please try again.',
    );
  }

  Future<http.Response> _postWithRetry(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
    int retries = _defaultRetries,
  }) async {
    for (int attempt = 0;
        attempt <= retries;
        attempt++) {
      try {
        final response = await _client
            .post(
              uri,
              headers: headers,
              body: body,
            )
            .timeout(
              _postTimeout,
            );

        if (!_shouldRetryStatus(
          response.statusCode,
        )) {
          return response;
        }

        if (attempt == retries) {
          return response;
        }
      } on TimeoutException {
        if (attempt == retries) {
          break;
        }
      } on http.ClientException {
        if (attempt == retries) {
          break;
        }
      } catch (_) {
        if (attempt == retries) {
          break;
        }
      }

      await Future.delayed(
        _retryDelay(attempt),
      );
    }

    throw const LocationServiceException(
      type: LocationServiceErrorType.network,
      message:
          'Unable to connect. Please check your internet connection.',
    );
  }

  // -------------------------------------------------------
  // CURRENT COORDINATES
  // -------------------------------------------------------

  Future<Position> getCurrentCoordinates() async {
    await _ensureLocationReady();

    final lastKnown =
        await Geolocator.getLastKnownPosition();

    if (lastKnown != null) {
      final age = DateTime.now()
          .difference(lastKnown.timestamp)
          .inSeconds;

      if (age <=
              _freshLocationMaxAgeSeconds &&
          _isWithinBeninCityArea(
            lastKnown.latitude,
            lastKnown.longitude,
          )) {
        return lastKnown;
      }
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 6),
        ),
      );
    } catch (_) {
      return Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
    }
  }

  Future<LocationModel> getCurrentLocation({
    bool preferExactAddress = false,
  }) async {
    final position =
        await getCurrentCoordinates();

    return reverseGeocode(
      latitude: position.latitude,
      longitude: position.longitude,
      preferExactAddress:
          preferExactAddress,
      fallbackLabel: 'Current location',
    );
  }

  // -------------------------------------------------------
  // REVERSE GEOCODING - WANPADI BACKEND
  // -------------------------------------------------------

  Future<LocationModel> reverseGeocode({
    required double latitude,
    required double longitude,
    bool preferExactAddress = false,
    String fallbackLabel = 'Selected location',
  }) async {
    if (!_isWithinBeninCityArea(
      latitude,
      longitude,
    )) {
      throw const LocationServiceException(
        type:
            LocationServiceErrorType.outsideServiceArea,
        message:
            'Wanpadi currently serves locations within Benin City.',
      );
    }

    final uri = Uri.https(
      _backendHost,
      '/places/reverse-geocode',
    );

    try {
      final response =
          await _postWithRetry(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'lat': latitude,
          'lng': longitude,
        }),
      );

      if (response.statusCode != 200) {
        return _pinnedLocationFallback(
          latitude,
          longitude,
          label: fallbackLabel,
        );
      }

      final data =
          jsonDecode(response.body);

      if (data is! Map ||
          data['success'] != true ||
          data['location'] is! Map) {
        return _pinnedLocationFallback(
          latitude,
          longitude,
          label: fallbackLabel,
        );
      }

      final location =
          Map<String, dynamic>.from(
        data['location'] as Map,
      );

      final address =
          location['address']
                  ?.toString()
                  .trim() ??
              '';

      if (address.isEmpty) {
        return _pinnedLocationFallback(
          latitude,
          longitude,
          label: fallbackLabel,
        );
      }

      return LocationModel(
        latitude: latitude,
        longitude: longitude,
        address: address,
        shortAddress:
            location['shortAddress']
                    ?.toString()
                    .trim() ??
                address.split(',').first.trim(),
        city:
            location['city']?.toString() ??
                'Benin City',
        state:
            location['state']?.toString() ??
                'Edo',
        country:
            location['country']?.toString() ??
                'Nigeria',
      );
    } on LocationServiceException {
      return _pinnedLocationFallback(
        latitude,
        longitude,
        label: fallbackLabel,
      );
    } catch (_) {
      return _pinnedLocationFallback(
        latitude,
        longitude,
        label: fallbackLabel,
      );
    }
  }

  LocationModel _pinnedLocationFallback(
    double latitude,
    double longitude, {
    required String label,
  }) {
    return LocationModel(
      latitude: latitude,
      longitude: longitude,
      address: label,
      shortAddress: label,
      city: 'Benin City',
      state: 'Edo',
      country: 'Nigeria',
    );
  }

  // -------------------------------------------------------
  // ADDRESS AUTOCOMPLETE - WANPADI BACKEND
  // -------------------------------------------------------

  Future<List<LocationSuggestionModel>>
      searchAddresses(
    String query,
  ) async {
    final cleanQuery = query.trim();

    if (cleanQuery.length < 2) {
      return [];
    }

    final uri = Uri.https(
      _backendHost,
      '/places/autocomplete',
    );

    final response =
        await _postAutocompleteWithRetry(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'query': cleanQuery,
      }),
    );

    if (response.statusCode != 200) {
      throw const LocationServiceException(
        type: LocationServiceErrorType.api,
        message:
            'Having trouble loading locations. Please try again.',
      );
    }

    Map<String, dynamic> data;

    try {
      data = Map<String, dynamic>.from(
        jsonDecode(response.body) as Map,
      );
    } catch (_) {
      throw const LocationServiceException(
        type: LocationServiceErrorType.api,
        message:
            'Having trouble loading locations. Please try again.',
      );
    }

    if (data['success'] != true) {
      throw const LocationServiceException(
        type: LocationServiceErrorType.api,
        message:
            'Having trouble loading locations. Please try again.',
      );
    }

    final suggestions =
        data['suggestions'] as List? ?? [];

    final results =
        <LocationSuggestionModel>[];

    for (final item in suggestions) {
      if (item is! Map) {
        continue;
      }

      final placeId =
          item['placeId']
                  ?.toString()
                  .trim() ??
              '';

      final title =
          item['title']
                  ?.toString()
                  .trim() ??
              '';

      final subtitle =
          item['subtitle']
                  ?.toString()
                  .trim() ??
              '';

      if (placeId.isEmpty ||
          title.isEmpty) {
        continue;
      }

      results.add(
        LocationSuggestionModel(
          placeId: placeId,
          title: title,
          subtitle: subtitle,
        ),
      );
    }

    return results;
  }

  // -------------------------------------------------------
  // PLACE DETAILS - WANPADI BACKEND
  // -------------------------------------------------------

  Future<LocationModel> getPlaceDetails(
    String placeId,
  ) async {
    final cleanPlaceId =
        placeId.trim();

    if (cleanPlaceId.isEmpty) {
      throw const LocationServiceException(
        type:
            LocationServiceErrorType.placeNotFound,
        message:
            'Location could not be found.',
      );
    }

    final uri = Uri.https(
      _backendHost,
      '/places/details',
    );

    final response =
        await _postWithRetry(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'placeId': cleanPlaceId,
      }),
    );

    Map<String, dynamic>? data;

    try {
      data = Map<String, dynamic>.from(
        jsonDecode(response.body) as Map,
      );
    } catch (_) {
      data = null;
    }

    if (response.statusCode == 400 &&
        data?['code'] ==
            'OUTSIDE_SERVICE_AREA') {
      throw const LocationServiceException(
        type: LocationServiceErrorType
            .outsideServiceArea,
        message:
            'Wanpadi currently serves locations within Benin City.',
      );
    }

    if (response.statusCode != 200 ||
        data == null ||
        data['success'] != true ||
        data['location'] is! Map) {
      throw const LocationServiceException(
        type:
            LocationServiceErrorType.placeNotFound,
        message:
            'Location could not be found.',
      );
    }

    final location =
        Map<String, dynamic>.from(
      data['location'] as Map,
    );

    final latitude =
        (location['latitude'] as num?)
            ?.toDouble();

    final longitude =
        (location['longitude'] as num?)
            ?.toDouble();

    if (latitude == null ||
        longitude == null) {
      throw const LocationServiceException(
        type:
            LocationServiceErrorType.placeNotFound,
        message:
            'Location could not be found.',
      );
    }

    if (!_isWithinBeninCityArea(
      latitude,
      longitude,
    )) {
      throw const LocationServiceException(
        type: LocationServiceErrorType
            .outsideServiceArea,
        message:
            'Wanpadi currently serves locations within Benin City.',
      );
    }

    final address =
        location['address']
                ?.toString()
                .trim() ??
            '';

    final shortAddress =
        location['shortAddress']
                ?.toString()
                .trim() ??
            location['name']
                ?.toString()
                .trim() ??
            '';

    return LocationModel(
      latitude: latitude,
      longitude: longitude,
      address: address,
      shortAddress: shortAddress,
      city:
          location['city']?.toString() ??
              'Benin City',
      state:
          location['state']?.toString() ??
              'Edo',
      country:
          location['country']?.toString() ??
              'Nigeria',
    );
  }

  // -------------------------------------------------------
  // LIVE TRACKING
  // -------------------------------------------------------

  void startLiveTracking(
    void Function(Position position)
        onUpdate,
  ) {
    _liveLocationSubscription
        ?.cancel();

    _liveLocationSubscription =
        Geolocator.getPositionStream(
      locationSettings:
          const LocationSettings(
        accuracy:
            LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    ).listen(
      onUpdate,
    );
  }

  Future<void> stopLiveTracking() async {
    await _liveLocationSubscription
        ?.cancel();

    _liveLocationSubscription = null;
  }

  // -------------------------------------------------------
  // ROUTING
  // -------------------------------------------------------

  Future<RouteResult>
      getRouteDistanceAndDuration({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
  }) async {
    final uri = Uri.parse(
      'https://routes.googleapis.com/directions/v2:computeRoutes',
    );

    final headers = {
      'Content-Type':
          'application/json',
      'X-Goog-Api-Key':
          GooglePlacesConfig.apiKey,
      'X-Goog-FieldMask':
          'routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline',
    };

    final body = jsonEncode({
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
            'latitude':
                destinationLat,
            'longitude':
                destinationLng,
          },
        },
      },
      'travelMode': 'DRIVE',
      'routingPreference':
          'TRAFFIC_AWARE',
    });

    final response =
        await _postWithRetry(
      uri,
      headers: headers,
      body: body,
    );

    if (response.statusCode != 200) {
      throw const LocationServiceException(
        type: LocationServiceErrorType.api,
        message:
            'Unable to calculate the route right now.',
      );
    }

    final data =
        jsonDecode(response.body);

    final routes =
        data['routes'] as List?;

    if (routes == null ||
        routes.isEmpty) {
      throw const LocationServiceException(
        type:
            LocationServiceErrorType.routeNotFound,
        message:
            'No route could be found.',
      );
    }

    final route = routes.first;

    return RouteResult(
      distanceMeters:
          (route['distanceMeters']
                  as num)
              .toDouble(),
      durationText:
          route['duration']
                  ?.toString() ??
              '0s',
      encodedPolyline:
          route['polyline']
                      ?['encodedPolyline']
                  ?.toString() ??
              '',
    );
  }

  Future<void> dispose() async {
    await stopLiveTracking();
    _client.close();
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