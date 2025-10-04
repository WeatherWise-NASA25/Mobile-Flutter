import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/location_model.dart';
import '../models/weather_model.dart';

class WeatherProvider extends ChangeNotifier {
  WeatherAnalysis? _currentAnalysis;
  bool _isLoading = false;
  String? _error;

  WeatherAnalysis? get currentAnalysis => _currentAnalysis;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Use your backend (local network) API as provided by your teammate
  final String backendUrl = 'http://10.30.21.222:8000/api/weather/';

  WeatherProvider();

  /// Fetch full analysis from backend and map it to the app models.
  /// Expected backend response shape (example):
  /// {
  ///   "forecast": { ... },
  ///   "historical_data": [ ... ],
  ///   "risk_assessment": { ... },
  ///   "recommendations": [ ... ],
  ///   "suitability_score": 0.85,
  ///   "analyzed_at": "2025-10-03T12:00:00Z"
  /// }
  Future<void> analyzeWeatherForEvent({
    required LocationModel location,
    required DateTime eventDate,
    required String eventType,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final dateString = eventDate.toIso8601String().split('T')[0];
      final uri = Uri.parse(
        '$backendUrl?lat=${location.latitude}&lon=${location.longitude}&date=$dateString&event_type=$eventType',
      );

      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 10), onTimeout: () => http.Response('"timeout"', 408));

      if (response.statusCode != 200) {
        _error = 'Failed to fetch weather data: ${response.statusCode}';
        notifyListeners();
        return;
      }

      final Map<String, dynamic> data = json.decode(response.body);

      // Defensive parsing with fallbacks
      final forecastJson = data['forecast'] as Map<String, dynamic>?;
      if (forecastJson == null) {
        _error = 'Backend response missing `forecast` field.';
        notifyListeners();
        return;
      }

      final forecast = WeatherData(
        date: DateTime.tryParse(forecastJson['date']?.toString() ?? '') ?? eventDate,
        temperature: (forecastJson['temperature_c'] as num?)?.toDouble() ?? 0.0,
        humidity: (forecastJson['humidity_percent'] as num?)?.toDouble() ?? 0.0,
        precipitation: (forecastJson['precipitation_mm'] as num?)?.toDouble() ?? 0.0,
        windSpeed: (forecastJson['wind_speed_ms'] as num?)?.toDouble() ?? 0.0,
        windDirection: (forecastJson['wind_direction_deg'] as num?)?.toDouble() ?? 0.0,
        cloudCover: (forecastJson['cloud_cover_percent'] as num?)?.toDouble() ?? 0.0,
        visibility: (forecastJson['visibility_km'] as num?)?.toDouble() ?? 0.0,
        // **Fix:** include pressure field expected by the WeatherData constructor.
        pressure: (forecastJson['pressure_hpa'] as num?)?.toDouble() ?? (forecastJson['pressure'] as num?)?.toDouble() ?? 1013.25,
        description: forecastJson['description']?.toString() ?? _generateSimpleDescriptionFromForecast(forecastJson),
        icon: forecastJson['icon']?.toString() ?? _generateSimpleIconFromForecast(forecastJson),
      );

      final historical = <WeatherData>[];
      final histList = data['historical_data'] as List<dynamic>?;
      if (histList != null) {
        for (final h in histList) {
          if (h is Map<String, dynamic>) {
            historical.add(WeatherData(
              date: DateTime.tryParse(h['date']?.toString() ?? '') ?? eventDate,
              temperature: (h['temperature_c'] as num?)?.toDouble() ?? 0.0,
              humidity: (h['humidity_percent'] as num?)?.toDouble() ?? 0.0,
              precipitation: (h['precipitation_mm'] as num?)?.toDouble() ?? 0.0,
              windSpeed: (h['wind_speed_ms'] as num?)?.toDouble() ?? 0.0,
              windDirection: (h['wind_direction_deg'] as num?)?.toDouble() ?? 0.0,
              cloudCover: (h['cloud_cover_percent'] as num?)?.toDouble() ?? 0.0,
              visibility: (h['visibility_km'] as num?)?.toDouble() ?? 0.0,
              pressure: (h['pressure_hpa'] as num?)?.toDouble() ?? (h['pressure'] as num?)?.toDouble() ?? 1013.25,
              description: h['description']?.toString() ?? '',
              icon: h['icon']?.toString() ?? '',
            ));
          }
        }
      }

      final riskJson = (data['risk_assessment'] as Map<String, dynamic>?) ?? {};
      final recommendations = <String>[];
      if (data['recommendations'] is List) {
        try {
          recommendations.addAll(List<String>.from(data['recommendations']));
        } catch (_) {}
      }

      // If backend didn't send recommendations, generate simple, useful ones locally
      if (recommendations.isEmpty) {
        final tempRisk = (riskJson['temperature_risk'] as num?)?.toDouble() ?? 0.0;
        final precipRisk = (riskJson['precipitation_risk'] as num?)?.toDouble() ?? 0.0;
        final windRisk = (riskJson['wind_risk'] as num?)?.toDouble() ?? 0.0;
        final visibilityRisk = (riskJson['visibility_risk'] as num?)?.toDouble() ?? 0.0;

        final riskObj = WeatherRiskAssessment(
          precipitationRisk: precipRisk,
          temperatureRisk: tempRisk,
          windRisk: windRisk,
          visibilityRisk: visibilityRisk,
          overallRisk: (riskJson['overall'] as num?)?.toDouble() ?? 0.0,
          details: riskJson,
        );

        recommendations.addAll(_generateSimpleRecommendations(forecast, riskObj, eventType));
      }

      final risk = WeatherRiskAssessment(
        precipitationRisk: (riskJson['precipitation_risk'] as num?)?.toDouble() ?? (riskJson['precipitation'] as num?)?.toDouble() ?? 0.0,
        temperatureRisk: (riskJson['temperature_risk'] as num?)?.toDouble() ?? 0.0,
        windRisk: (riskJson['wind_risk'] as num?)?.toDouble() ?? 0.0,
        visibilityRisk: (riskJson['visibility_risk'] as num?)?.toDouble() ?? 0.0,
        overallRisk: (riskJson['overall'] as num?)?.toDouble() ?? (data['overall_risk'] as num?)?.toDouble() ?? 0.0,
        details: riskJson,
      );

      final analysis = WeatherAnalysis(
        location: location,
        eventDate: eventDate,
        eventType: eventType,
        forecast: forecast,
        historicalData: historical,
        riskAssessment: risk,
        recommendations: recommendations,
        suitabilityScore: (data['suitability_score'] as num?)?.toDouble() ?? _calculateSuitabilityFromRisk(risk),
        analyzedAt: DateTime.tryParse(data['analyzed_at']?.toString() ?? '') ?? DateTime.now(),
      );

      _currentAnalysis = analysis;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to fetch weather data: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  double _calculateSuitabilityFromRisk(WeatherRiskAssessment risk) {
    return (1.0 - (risk.overallRisk)).clamp(0.0, 1.0);
  }

  String _generateSimpleDescriptionFromForecast(Map<String, dynamic> f) {
    final precip = (f['precipitation_mm'] as num?)?.toDouble() ?? 0.0;
    final temp = (f['temperature_c'] as num?)?.toDouble() ?? 0.0;
    if (precip > 10) return 'Heavy rain expected';
    if (precip > 1) return 'Light rain possible';
    if (temp > 30) return 'Hot and sunny';
    if (temp < 5) return 'Cold conditions';
    return 'Mild weather';
  }

  String _generateSimpleIconFromForecast(Map<String, dynamic> f) {
    final precip = (f['precipitation_mm'] as num?)?.toDouble() ?? 0.0;
    final temp = (f['temperature_c'] as num?)?.toDouble() ?? 0.0;
    if (precip > 10) return '⛈️';
    if (precip > 1) return '🌧️';
    if (temp > 30) return '🔥';
    if (temp < 0) return '❄️';
    return '☀️';
  }

  /// Generates a short list of human-friendly recommendations if backend didn't provide any.
  List<String> _generateSimpleRecommendations(WeatherData forecast, WeatherRiskAssessment risk, String eventType) {
    final recs = <String>[];

    if (risk.precipitationRisk > 0.8) {
      recs.add('Heavy precipitation expected — prefer an indoor venue or cover for outdoor areas.');
      recs.add('Ensure drainage and shelter plans are ready.');
    } else if (risk.precipitationRisk > 0.4) {
      recs.add('Moderate chance of rain — have umbrellas, tarps or tents available.');
    } else {
      recs.add('Low precipitation risk — outdoor arrangements likely safe.');
    }

    if (risk.temperatureRisk > 0.6) {
      if (forecast.temperature > 32) {
        recs.add('High temperature expected — provide cooling stations and extra water.');
      } else {
        recs.add('Cold expected — provide heating or warm areas.');
      }
    }

    if (risk.windRisk > 0.4) {
      recs.add('High wind risk — secure light structures and equipment.');
    }

    if (risk.visibilityRisk > 0.6) {
      recs.add('Low visibility expected — consider additional lighting and signage.');
    }

    recs.add('Analysis powered by your backend weather service.');
    return recs;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearAnalysis() {
    _currentAnalysis = null;
    _error = null;
    notifyListeners();
  }
}
