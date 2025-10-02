class LocationModel {
  final String name;
  final String country;
  final double latitude;
  final double longitude;
  final String? timezone;
  final String? address;
  final DateTime? selectedAt;

  LocationModel({
    required this.name,
    required this.country,
    required this.latitude,
    required this.longitude,
    this.timezone,
    this.address,
    this.selectedAt,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      name: json['name'] ?? '',
      country: json['country'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      timezone: json['timezone'],
      address: json['address'],
      selectedAt: json['selected_at'] != null 
          ? DateTime.parse(json['selected_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'timezone': timezone,
      'address': address,
      'selected_at': selectedAt?.toIso8601String(),
    };
  }

  LocationModel copyWith({
    String? name,
    String? country,
    double? latitude,
    double? longitude,
    String? timezone,
    String? address,
    DateTime? selectedAt,
  }) {
    return LocationModel(
      name: name ?? this.name,
      country: country ?? this.country,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timezone: timezone ?? this.timezone,
      address: address ?? this.address,
      selectedAt: selectedAt ?? this.selectedAt,
    );
  }

  String get coordinates => '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  
  String get displayName => '$name, $country';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationModel &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;

  @override
  String toString() {
    return 'LocationModel(name: $name, country: $country, lat: $latitude, lon: $longitude)';
  }
}