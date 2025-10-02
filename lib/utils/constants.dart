import 'package:flutter/material.dart';

class AppConstants {
  // API Configuration
  static const String baseUrl = 'https://api.weatherwise.com';
  static const String nasaApiUrl = 'https://api.nasa.gov';

  // Map Configuration
  static const double defaultLatitude = 30.0444; // Cairo
  static const double defaultLongitude = 31.2357;
  static const double defaultZoom = 4.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  static const double defaultRadius = 16.0;
  static const double smallRadius = 8.0;
  static const double largeRadius = 24.0;

  // Weather Analysis Thresholds
  static const double lowRiskThreshold = 0.3;
  static const double mediumRiskThreshold = 0.6;
  static const double highRiskThreshold = 0.8;

  // Event Types
  static const List<String> eventTypes = [
    'Wedding',
    'Concert',
    'Festival',
    'Sports Event',
    'Conference',
    'Parade',
    'Picnic',
    'Corporate Event',
    'Art Exhibition',
    'Food Festival',
    'Marathon',
    'Other',
  ];

  // Event Icons
  static const Map<String, IconData> eventIcons = {
    'Wedding': Icons.favorite,
    'Concert': Icons.music_note,
    'Festival': Icons.celebration,
    'Sports Event': Icons.sports_soccer,
    'Conference': Icons.business,
    'Parade': Icons.flag,
    'Picnic': Icons.outdoor_grill,
    'Corporate Event': Icons.business_center,
    'Art Exhibition': Icons.palette,
    'Food Festival': Icons.restaurant,
    'Marathon': Icons.directions_run,
    'Other': Icons.event,
  };

  // Colors for Risk Levels
  static const Color lowRiskColor = Colors.green;
  static const Color mediumRiskColor = Colors.orange;
  static const Color highRiskColor = Colors.red;

  // Sample Locations for Demo
  // تم تغيير الاسم من sampleLocations إلى sampleLocationDetails لحل الخطأ
  static const List<Map<String, dynamic>> sampleLocationDetails = [
    {
      'name': 'New York City, USA',
      'country': 'United States',
      'latitude': 40.7128,
      'longitude': -74.0060,
      'timezone': 'America/New_York',
    },
    {
      'name': 'London, UK',
      'country': 'United Kingdom',
      'latitude': 51.5074,
      'longitude': -0.1278,
      'timezone': 'Europe/London',
    },
    {
      'name': 'Tokyo, Japan',
      'country': 'Japan',
      'latitude': 35.6762,
      'longitude': 139.6503,
      'timezone': 'Asia/Tokyo',
    },
    {
      'name': 'Sydney, Australia',
      'country': 'Australia',
      'latitude': -33.8688,
      'longitude': 151.2093,
      'timezone': 'Australia/Sydney',
    },
    {
      'name': 'Cairo, Egypt',
      'country': 'Egypt',
      'latitude': 30.0444,
      'longitude': 31.2357,
      'timezone': 'Africa/Cairo',
    },
    {
      'name': 'São Paulo, Brazil',
      'country': 'Brazil',
      'latitude': -23.5505,
      'longitude': -46.6333,
      'timezone': 'America/Sao_Paulo',
    },
    {
      'name': 'Mumbai, India',
      'country': 'India',
      'latitude': 19.0760,
      'longitude': 72.8777,
      'timezone': 'Asia/Kolkata',
    },
    {
      'name': 'Cape Town, South Africa',
      'country': 'South Africa',
      'latitude': -33.9249,
      'longitude': 18.4241,
      'timezone': 'Africa/Johannesburg',
    },
  ];
}

// Utility Extensions
extension DateTimeExtensions on DateTime {
  String get formattedDate {
    return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';
  }

  String get formattedDateTime {
    return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}

extension StringExtensions on String {
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}