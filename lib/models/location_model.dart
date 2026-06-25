class LocationModel {
  final double latitude;
  final double longitude;
  final String address;
  final String? name;
  final String? shortAddress;
  final String? placeId;
  final String? city;
  final String? state;
  final String? country;

  const LocationModel({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.name,
    this.shortAddress,
    this.placeId,
    this.city,
    this.state,
    this.country,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'name': name,
      'shortAddress': shortAddress,
      'placeId': placeId,
      'city': city,
      'state': state,
      'country': country,
    };
  }

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address']?.toString() ?? '',
      name: json['name']?.toString(),
      shortAddress: json['shortAddress']?.toString(),
      placeId: json['placeId']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      country: json['country']?.toString(),
    );
  }
}
