import '../models/location_model.dart'; // Add this import

class WeatherData {
  final DateTime date;
  final double temperature;
  final double humidity;
  final double precipitation;
  final double windSpeed;
  final double windDirection;
  final double cloudCover;
  final double pressure;
  final double visibility;
  final String description;
  final String icon;

  WeatherData({
    required this.date,
    required this.temperature,
    required this.humidity,
    required this.precipitation,
    required this.windSpeed,
    required this.windDirection,
    required this.cloudCover,
    required this.pressure,
    required this.visibility,
    required this.description,
    required this.icon,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      date: DateTime.parse(json['date']),
      temperature: (json['temperature'] ?? 0.0).toDouble(),
      humidity: (json['humidity'] ?? 0.0).toDouble(),
      precipitation: (json['precipitation'] ?? 0.0).toDouble(),
      windSpeed: (json['wind_speed'] ?? 0.0).toDouble(),
      windDirection: (json['wind_direction'] ?? 0.0).toDouble(),
      cloudCover: (json['cloud_cover'] ?? 0.0).toDouble(),
      pressure: (json['pressure'] ?? 0.0).toDouble(),
      visibility: (json['visibility'] ?? 0.0).toDouble(),
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'temperature': temperature,
      'humidity': humidity,
      'precipitation': precipitation,
      'wind_speed': windSpeed,
      'wind_direction': windDirection,
      'cloud_cover': cloudCover,
      'pressure': pressure,
      'visibility': visibility,
      'description': description,
      'icon': icon,
    };
  }

  // Getters for formatted values
  String get formattedTemperature => '${temperature.round()}°C';
  String get formattedHumidity => '${humidity.round()}%';
  String get formattedPrecipitation => '${precipitation.toStringAsFixed(1)}mm';
  String get formattedWindSpeed => '${windSpeed.round()} km/h';
  String get formattedCloudCover => '${cloudCover.round()}%';
  String get formattedPressure => '${pressure.round()} hPa';
  String get formattedVisibility => '${visibility.round()} km';
}

class WeatherAnalysis {
  final LocationModel location;
  final DateTime eventDate;
  final String eventType;
  final List<WeatherData> historicalData;
  final WeatherData forecast;
  final WeatherRiskAssessment riskAssessment;
  final List<String> recommendations;
  final double suitabilityScore;
  final DateTime analyzedAt;

  WeatherAnalysis({
    required this.location,
    required this.eventDate,
    required this.eventType,
    required this.historicalData,
    required this.forecast,
    required this.riskAssessment,
    required this.recommendations,
    required this.suitabilityScore,
    required this.analyzedAt,
  });

  factory WeatherAnalysis.fromJson(Map<String, dynamic> json) {
    return WeatherAnalysis(
      location: LocationModel.fromJson(json['location']),
      eventDate: DateTime.parse(json['event_date']),
      eventType: json['event_type'] ?? '',
      historicalData: (json['historical_data'] as List<dynamic>?)
          ?.map((data) => WeatherData.fromJson(data))
          .toList() ?? [],
      forecast: WeatherData.fromJson(json['forecast']),
      riskAssessment: WeatherRiskAssessment.fromJson(json['risk_assessment']),
      recommendations: List<String>.from(json['recommendations'] ?? []),
      suitabilityScore: (json['suitability_score'] ?? 0.0).toDouble(),
      analyzedAt: DateTime.parse(json['analyzed_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'location': location.toJson(),
      'event_date': eventDate.toIso8601String(),
      'event_type': eventType,
      'historical_data': historicalData.map((data) => data.toJson()).toList(),
      'forecast': forecast.toJson(),
      'risk_assessment': riskAssessment.toJson(),
      'recommendations': recommendations,
      'suitability_score': suitabilityScore,
      'analyzed_at': analyzedAt.toIso8601String(),
    };
  }

  String get riskLevel {
    if (suitabilityScore >= 0.8) return 'Low';
    if (suitabilityScore >= 0.5) return 'Medium';
    return 'High';
  }

  String get formattedSuitabilityScore => '${(suitabilityScore * 100).round()}%';
}

class WeatherRiskAssessment {
  final double precipitationRisk;
  final double temperatureRisk;
  final double windRisk;
  final double visibilityRisk;
  final double overallRisk;
  final Map<String, dynamic> details;

  WeatherRiskAssessment({
    required this.precipitationRisk,
    required this.temperatureRisk,
    required this.windRisk,
    required this.visibilityRisk,
    required this.overallRisk,
    required this.details,
  });

  factory WeatherRiskAssessment.fromJson(Map<String, dynamic> json) {
    return WeatherRiskAssessment(
      precipitationRisk: (json['precipitation_risk'] ?? 0.0).toDouble(),
      temperatureRisk: (json['temperature_risk'] ?? 0.0).toDouble(),
      windRisk: (json['wind_risk'] ?? 0.0).toDouble(),
      visibilityRisk: (json['visibility_risk'] ?? 0.0).toDouble(),
      overallRisk: (json['overall_risk'] ?? 0.0).toDouble(),
      details: json['details'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'precipitation_risk': precipitationRisk,
      'temperature_risk': temperatureRisk,
      'wind_risk': windRisk,
      'visibility_risk': visibilityRisk,
      'overall_risk': overallRisk,
      'details': details,
    };
  }

  String getRiskLevel(double risk) {
    if (risk <= 0.3) return 'Low';
    if (risk <= 0.6) return 'Medium';
    return 'High';
  }
}