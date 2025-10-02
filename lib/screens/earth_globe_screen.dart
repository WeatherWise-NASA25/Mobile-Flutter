import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// flutter_earth_globe imports (مهمّة: استورد الملفات الخاصة عشان تلاقي الـ classes)
import 'package:flutter_earth_globe/flutter_earth_globe.dart';
import 'package:flutter_earth_globe/flutter_earth_globe_controller.dart';
import 'package:flutter_earth_globe/globe_coordinates.dart';
import 'package:flutter_earth_globe/point.dart';
// import 'package:flutter_earth_globe/visible_point.dart'; // تم حذف هذا الاستيراد

import 'package:provider/provider.dart';

import '../providers/location_provider.dart';
import '../models/location_model.dart';
import '../utils/constants.dart';
import '../widgets/location_selection_sheet.dart';
import '../widgets/gradient_background.dart';

class EarthGlobeScreen extends StatefulWidget {
  const EarthGlobeScreen({super.key});

  @override
  State<EarthGlobeScreen> createState() => _EarthGlobeScreenState();
}

class _EarthGlobeScreenState extends State<EarthGlobeScreen>
    with TickerProviderStateMixin {
  late FlutterEarthGlobeController _globeController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isGlobeReady = false;
  bool _showInstructions = true;

  @override
  void initState() {
    super.initState();
    _initializeGlobe();
    _setupAnimations();
    _hideInstructionsAfterDelay();
  }

  void _initializeGlobe() {
    _globeController = FlutterEarthGlobeController(
      rotationSpeed: 0.01,
      isBackgroundFollowingSphereRotation: true,
      isRotating: true,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupGlobeAppearance();
    });
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  // -------------------------------------------------------------------
  // NOTE: loadBackground/loadSurface return void in this package version,
  // so don't await them and don't pass unknown named params.
  // -------------------------------------------------------------------
  Future<void> _setupGlobeAppearance() async {
    try {
      // غيّر مسارات الأصول لو عندك أسماء مختلفة في المشروع
      _globeController.loadBackground(Image.asset('assets/2k_stars.jpg').image);
      _globeController.loadSurface(Image.asset('assets/2k_earth-day.jpg').image);

      _addSampleLocationPoints();

      setState(() {
        _isGlobeReady = true;
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error setting up globe: $e');
      setState(() {
        _isGlobeReady = true;
      });
    }
  }

  void _addSampleLocationPoints() {
    final list = AppConstants.sampleLocationDetails;

    for (int i = 0; i < list.length; i++) {
      final location = list[i];

      final double lat = (location['latitude'] as num).toDouble();
      final double lng = (location['longitude'] as num).toDouble();
      final String name = location['name']?.toString() ?? 'Location $i';

      final point = Point(
        id: 'location_$i',
        coordinates: GlobeCoordinates(lat, lng),
        label: name,
        isLabelVisible: false,
        // تم حل خطأ 'VisiblePointStyle' باستبدالها بـ 'PointStyle'
        style: const PointStyle(
          color: Colors.amber,
          size: 6,
        ),
        onTap: () => _onLocationTapped(location),
        onHover: () => _onLocationHovered(location),
      );

      _globeController.addPoint(point);
    }
  }

  void _onLocationTapped(Map<String, dynamic> locationData) {
    HapticFeedback.lightImpact();

    final location = LocationModel(
      name: locationData['name']?.toString() ?? 'Unknown',
      country: locationData['country']?.toString() ?? 'Unknown',
      latitude: (locationData['latitude'] as num).toDouble(),
      longitude: (locationData['longitude'] as num).toDouble(),
      timezone: locationData['timezone']?.toString(),
    );

    context.read<LocationProvider>().setSelectedLocation(location);
    _showLocationSelectionSheet(location);
  }

  void _onLocationHovered(Map<String, dynamic> locationData) {
    setState(() {
      // اختياري: عرض اسم قصير أو تأثير
    });
  }

  void _onGlobeTapped(GlobeCoordinates coordinates) {
    HapticFeedback.mediumImpact();

    final location = LocationModel(
      name: 'Custom Location',
      country: 'Unknown',
      latitude: coordinates.latitude,
      longitude: coordinates.longitude,
    );

    context.read<LocationProvider>().setSelectedLocation(location);
    _showLocationSelectionSheet(location);
  }

  void _showLocationSelectionSheet(LocationModel location) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationSelectionSheet(location: location),
    );
  }

  void _hideInstructionsAfterDelay() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showInstructions = false;
        });
      }
    });
  }

  void _resetGlobeRotation() {
    // animateTo غير مدعومة في نسخة الحزمة؛ بنستخدم resetRotation بدلها
    _globeController.resetRotation();
  }

  @override
  void dispose() {
    _globeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'WeatherWise',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: const Offset(0, 1),
                blurRadius: 3,
                color: Colors.black.withOpacity(0.5),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () => _showInfoDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _resetGlobeRotation,
          ),
        ],
      ),
      body: Stack(
        children: [
          const GradientBackground(),

          if (_isGlobeReady)
            Positioned.fill(
              child: GestureDetector(
                onTapDown: (details) {
                  final RenderBox renderBox = context.findRenderObject() as RenderBox;
                  final localPosition = renderBox.globalToLocal(details.globalPosition);

                  final centerX = size.width / 2;
                  final centerY = size.height / 2;
                  final radius = 150.0;

                  final dx = localPosition.dx - centerX;
                  final dy = localPosition.dy - centerY;
                  final distanceSquared = dx * dx + dy * dy;

                  if (distanceSquared <= radius * radius) {
                    final lat = (dy / radius) * -90;
                    final lng = (dx / radius) * 180;

                    final clampedLat = lat.clamp(-90.0, 90.0);
                    final clampedLng = lng.clamp(-180.0, 180.0);

                    _onGlobeTapped(GlobeCoordinates(clampedLat, clampedLng));
                  }
                },
                child: Center(
                  child: FlutterEarthGlobe(
                    controller: _globeController,
                    radius: 150,
                  ),
                ),
              ),
            )
          else
            Positioned.fill(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue.withOpacity(0.3),
                              border: Border.all(
                                color: Colors.blue,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.public,
                              color: Colors.blue,
                              size: 50,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Loading Earth...',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (_showInstructions && _isGlobeReady)
            Positioned(
              top: 120,
              left: 20,
              right: 20,
              child: AnimatedOpacity(
                opacity: _showInstructions ? 1.0 : 0.0,
                duration: AppConstants.mediumAnimation,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.touch_app,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tap anywhere on Earth to select a location',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.amber,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Golden dots show popular destinations',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showInstructions = false;
                          });
                        },
                        child: Text(
                          'Got it!',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.blue[300],
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          Positioned(
            bottom: 30,
            right: 20,
            child: FloatingActionButton.extended(
              onPressed: () {
                _showLocationSearchDialog();
              },
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.search),
              label: const Text('Search Location'),
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Location'),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'Enter city name...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('About WeatherWise'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WeatherWise helps you plan perfect outdoor events using NASA Earth observation data.',
              style: TextStyle(fontSize: 16, height: 1.4),
            ),
            SizedBox(height: 12),
            Text('Features:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('• Interactive 3D Earth globe navigation'),
            Text('• Real-time weather analysis'),
            Text('• Event suitability assessment'),
            Text('• Risk predictions and recommendations'),
            Text('• Historical weather data insights'),
            SizedBox(height: 12),
            Text(
              'Powered by NASA GPM IMERG, MODIS, and Landsat satellite data.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------------
// تذكير: يجب أن يحتوي ملف '../utils/constants.dart' على الكلاس AppConstants
//
// مثال لملف '../utils/constants.dart' (للتوضيح فقط، يجب عليك إنشاؤه):
//
/*
import 'package:flutter/material.dart';

class AppConstants {
  static const Duration mediumAnimation = Duration(milliseconds: 500);

  static const List<Map<String, dynamic>> sampleLocationDetails = [
    {
      'name': 'New York',
      'country': 'USA',
      'latitude': 40.7128,
      'longitude': -74.0060,
      'timezone': 'EST',
    },
    {
      'name': 'Tokyo',
      'country': 'Japan',
      'latitude': 35.6895,
      'longitude': 139.6917,
      'timezone': 'JST',
    },
    {
      'name': 'Cairo',
      'country': 'Egypt',
      'latitude': 30.0333,
      'longitude': 31.2333,
      'timezone': 'EET',
    },
    // أضف المزيد من المواقع هنا...
  ];
}
*/
// -------------------------------------------------------------------