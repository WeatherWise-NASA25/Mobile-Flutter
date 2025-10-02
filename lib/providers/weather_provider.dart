import 'package:flutter/foundation.dart';
import 'dart:math';
import '../models/location_model.dart';
import '../models/weather_model.dart';

class WeatherProvider extends ChangeNotifier {
  WeatherAnalysis? _currentAnalysis;
  bool _isLoading = false;
  String? _error;

  WeatherAnalysis? get currentAnalysis => _currentAnalysis;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> analyzeWeatherForEvent({
    required LocationModel location,
    required DateTime eventDate,
    required String eventType,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 2));

      // Generate mock weather analysis
      final analysis = _generateMockWeatherAnalysis(
        location: location,
        eventDate: eventDate,
        eventType: eventType,
      );

      _currentAnalysis = analysis;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to analyze weather data: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  WeatherAnalysis _generateMockWeatherAnalysis({
    required LocationModel location,
    required DateTime eventDate,
    required String eventType,
  }) {
    final random = Random();
    
    // Generate historical data (last 10 years for same date)
    final historicalData = <WeatherData>[];
    for (int i = 1; i <= 10; i++) {
      final historicalDate = DateTime(eventDate.year - i, eventDate.month, eventDate.day);
      historicalData.add(_generateWeatherData(historicalDate, location, random));
    }

    // Generate forecast for event date
    final forecast = _generateWeatherData(eventDate, location, random);

    // Calculate risk assessment
    final riskAssessment = _calculateRiskAssessment(forecast, historicalData, eventType);

    // Generate recommendations
    final recommendations = _generateRecommendations(forecast, riskAssessment, eventType);

    // Calculate suitability score
    final suitabilityScore = _calculateSuitabilityScore(riskAssessment);

    return WeatherAnalysis(
      location: location,
      eventDate: eventDate,
      eventType: eventType,
      historicalData: historicalData,
      forecast: forecast,
      riskAssessment: riskAssessment,
      recommendations: recommendations,
      suitabilityScore: suitabilityScore,
      analyzedAt: DateTime.now(),
    );
  }

  WeatherData _generateWeatherData(DateTime date, LocationModel location, Random random) {
    // Base values influenced by location (simplified climate modeling)
    double baseTemp = 20.0; // Default temperature
    double basePrecip = 0.1; // Default precipitation chance
    
    // Adjust based on latitude (simplified)
    if (location.latitude.abs() > 60) {
      baseTemp = 0.0; // Arctic regions
    } else if (location.latitude.abs() < 30) {
      baseTemp = 28.0; // Tropical regions
    }

    // Seasonal adjustment
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    final seasonalFactor = sin((dayOfYear / 365.0) * 2 * pi);
    
    // Northern hemisphere vs Southern hemisphere
    final seasonAdjustment = location.latitude >= 0 ? seasonalFactor : -seasonalFactor;
    
    final temperature = baseTemp + (seasonAdjustment * 10) + (random.nextDouble() - 0.5) * 15;
    final humidity = 40 + random.nextDouble() * 50;
    final precipitation = random.nextDouble() < (basePrecip + seasonAdjustment * 0.05) 
        ? random.nextDouble() * 25 
        : 0.0;
    final windSpeed = 5 + random.nextDouble() * 20;
    final windDirection = random.nextDouble() * 360;
    final cloudCover = precipitation > 0 ? 60 + random.nextDouble() * 40 : random.nextDouble() * 60;
    final pressure = 1000 + random.nextDouble() * 50;
    final visibility = cloudCover > 80 ? 5 + random.nextDouble() * 10 : 10 + random.nextDouble() * 15;

    return WeatherData(
      date: date,
      temperature: temperature,
      humidity: humidity,
      precipitation: precipitation,
      windSpeed: windSpeed,
      windDirection: windDirection,
      cloudCover: cloudCover,
      pressure: pressure,
      visibility: visibility,
      description: _getWeatherDescription(temperature, precipitation, cloudCover),
      icon: _getWeatherIcon(temperature, precipitation, cloudCover),
    );
  }

  WeatherRiskAssessment _calculateRiskAssessment(
    WeatherData forecast,
    List<WeatherData> historicalData,
    String eventType,
  ) {
    // Calculate precipitation risk
    final precipitationRisk = _calculatePrecipitationRisk(forecast, historicalData);
    
    // Calculate temperature risk based on event type
    final temperatureRisk = _calculateTemperatureRisk(forecast, eventType);
    
    // Calculate wind risk
    final windRisk = _calculateWindRisk(forecast, eventType);
    
    // Calculate visibility risk
    final visibilityRisk = _calculateVisibilityRisk(forecast);

    // Overall risk is weighted average
    final overallRisk = (precipitationRisk * 0.4 + 
                        temperatureRisk * 0.3 + 
                        windRisk * 0.2 + 
                        visibilityRisk * 0.1).clamp(0.0, 1.0);

    return WeatherRiskAssessment(
      precipitationRisk: precipitationRisk,
      temperatureRisk: temperatureRisk,
      windRisk: windRisk,
      visibilityRisk: visibilityRisk,
      overallRisk: overallRisk,
      details: {
        'precipitation_mm': forecast.precipitation,
        'temperature_c': forecast.temperature,
        'wind_speed_kmh': forecast.windSpeed,
        'visibility_km': forecast.visibility,
        'historical_avg_precipitation': historicalData.map((d) => d.precipitation).reduce((a, b) => a + b) / historicalData.length,
      },
    );
  }

  double _calculatePrecipitationRisk(WeatherData forecast, List<WeatherData> historicalData) {
    if (forecast.precipitation <= 1.0) return 0.1;
    if (forecast.precipitation <= 5.0) return 0.3;
    if (forecast.precipitation <= 10.0) return 0.6;
    return 0.9;
  }

  double _calculateTemperatureRisk(WeatherData forecast, String eventType) {
    final temp = forecast.temperature;
    
    // Different event types have different temperature sensitivities
    switch (eventType.toLowerCase()) {
      case 'wedding':
      case 'conference':
        if (temp < 10 || temp > 35) return 0.8;
        if (temp < 15 || temp > 30) return 0.4;
        return 0.1;
      
      case 'sports event':
      case 'marathon':
        if (temp < 5 || temp > 32) return 0.9;
        if (temp < 10 || temp > 28) return 0.5;
        return 0.2;
      
      case 'picnic':
      case 'festival':
        if (temp < 12 || temp > 33) return 0.7;
        if (temp < 18 || temp > 28) return 0.3;
        return 0.1;
      
      default:
        if (temp < 0 || temp > 40) return 0.9;
        if (temp < 10 || temp > 35) return 0.5;
        return 0.2;
    }
  }

  double _calculateWindRisk(WeatherData forecast, String eventType) {
    final windSpeed = forecast.windSpeed;
    
    // Events with outdoor setups are more sensitive to wind
    final isWindSensitive = [
      'wedding', 'concert', 'festival', 'conference', 'art exhibition'
    ].contains(eventType.toLowerCase());
    
    if (isWindSensitive) {
      if (windSpeed > 25) return 0.8;
      if (windSpeed > 15) return 0.4;
      return 0.1;
    } else {
      if (windSpeed > 35) return 0.7;
      if (windSpeed > 25) return 0.3;
      return 0.1;
    }
  }

  double _calculateVisibilityRisk(WeatherData forecast) {
    final visibility = forecast.visibility;
    
    if (visibility < 5) return 0.8;
    if (visibility < 10) return 0.4;
    if (visibility < 15) return 0.2;
    return 0.1;
  }

  List<String> _generateRecommendations(
    WeatherData forecast,
    WeatherRiskAssessment riskAssessment,
    String eventType,
  ) {
    final recommendations = <String>[];

    // Precipitation recommendations
    if (riskAssessment.precipitationRisk > 0.6) {
      recommendations.add('⛈️ HIGH RAIN RISK: Strong recommendation for indoor backup venue');
      recommendations.add('🎪 Consider weatherproof tents or covered areas');
    } else if (riskAssessment.precipitationRisk > 0.3) {
      recommendations.add('🌦️ MODERATE RAIN RISK: Have umbrellas and light covers ready');
    } else {
      recommendations.add('☀️ MINIMAL RAIN RISK: Perfect conditions for outdoor activities');
    }

    // Temperature recommendations
    if (riskAssessment.temperatureRisk > 0.6) {
      if (forecast.temperature > 30) {
        recommendations.add('🔥 HIGH HEAT: Ensure adequate shade, cooling, and hydration stations');
        recommendations.add('❄️ Consider misting systems or air conditioning');
      } else {
        recommendations.add('🧥 COLD WEATHER: Provide heating and inform guests about warm clothing');
      }
    } else if (forecast.temperature > 25) {
      recommendations.add('🌡️ WARM CONDITIONS: Provide shade and cold refreshments');
    }

    // Wind recommendations
    if (riskAssessment.windRisk > 0.5) {
      recommendations.add('💨 HIGH WIND RISK: Secure all decorations, tents, and signage properly');
      recommendations.add('⚠️ Consider postponing if using large outdoor displays');
    }

    // Event-specific recommendations
    switch (eventType.toLowerCase()) {
      case 'wedding':
        if (forecast.temperature > 25) {
          recommendations.add('💐 Keep flowers in cool areas and provide fans for guests');
        }
        break;
      case 'sports event':
        if (forecast.temperature > 28) {
          recommendations.add('💧 Extra hydration breaks recommended for participants');
        }
        break;
      case 'concert':
      case 'festival':
        if (forecast.windSpeed > 15) {
          recommendations.add('🎵 Test sound equipment for wind interference');
        }
        break;
    }

    // General recommendations
    recommendations.add('📱 Monitor weather updates 24 hours before the event');
    recommendations.add('🚗 Inform guests about parking and transportation conditions');

    return recommendations;
  }

  double _calculateSuitabilityScore(WeatherRiskAssessment riskAssessment) {
    // Invert risk to get suitability (lower risk = higher suitability)
    return (1.0 - riskAssessment.overallRisk).clamp(0.0, 1.0);
  }

  String _getWeatherDescription(double temperature, double precipitation, double cloudCover) {
    if (precipitation > 10) return 'Heavy Rain';
    if (precipitation > 5) return 'Moderate Rain';
    if (precipitation > 1) return 'Light Rain';
    if (cloudCover > 80) return 'Overcast';
    if (cloudCover > 50) return 'Partly Cloudy';
    if (temperature > 30) return 'Hot';
    if (temperature < 5) return 'Cold';
    return 'Clear';
  }

  String _getWeatherIcon(double temperature, double precipitation, double cloudCover) {
    if (precipitation > 10) return '⛈️';
    if (precipitation > 1) return '🌧️';
    if (cloudCover > 80) return '☁️';
    if (cloudCover > 50) return '⛅';
    if (temperature > 30) return '🔥';
    if (temperature < 5) return '❄️';
    return '☀️';
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