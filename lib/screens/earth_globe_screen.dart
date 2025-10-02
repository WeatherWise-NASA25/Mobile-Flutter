import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:math';
import 'package:flutter_earth_globe/flutter_earth_globe.dart';
import 'package:flutter_earth_globe/flutter_earth_globe_controller.dart';
import 'package:flutter_earth_globe/globe_coordinates.dart';
import 'package:flutter_earth_globe/point.dart';

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
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeGlobe();
    _setupAnimations();
    _hideInstructionsAfterDelay();
  }

  void _initializeGlobe() {
    _globeController = FlutterEarthGlobeController(
      rotationSpeed: 0.02,
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
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _setupGlobeAppearance() async {
    try {
      // Try to load assets if they exist, otherwise continue without them
      try {
        _globeController.loadBackground(Image.asset('assets/images/stars.jpg').image);
      } catch (e) {
        print('Stars background not found, using default: $e');
      }

      try {
        _globeController.loadSurface(Image.asset('assets/images/earth_day.jpg').image);
      } catch (e) {
        print('Earth texture not found, using default: $e');
      }

      // Add location points
      _addSampleLocationPoints();

      // Wait a moment for globe to initialize
      await Future.delayed(const Duration(milliseconds: 800));

      setState(() {
        _isGlobeReady = true;
      });

      print('Globe setup complete - should be visible now');
    } catch (e) {
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

      try {
        final point = Point(
          id: 'location_$i',
          coordinates: GlobeCoordinates(lat, lng),
          label: name,
          isLabelVisible: true,
          style: const PointStyle(
            color: Colors.amber,
            size: 8,
          ),
          onTap: () => _onLocationTapped(location),
          onHover: () => _onLocationHovered(location),
        );

        _globeController.addPoint(point);
      } catch (e) {
        print('Error adding point $i: $e');
      }
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
    // Could show temporary tooltip or highlight
    setState(() {
      // Update UI if needed
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
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) {
        setState(() {
          _showInstructions = false;
        });
      }
    });
  }

  void _resetGlobeRotation() {
    try {
      _globeController.resetRotation();
    } catch (e) {
      print('Reset not available, reloading globe: $e');
      setState(() {
        _isGlobeReady = false;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isGlobeReady = true;
          });
        }
      });
    }
  }

  // FIXED: City search functionality
  Future<void> _searchCity(String cityName) async {
    if (cityName.trim().isEmpty) {
      _showErrorSnackBar('Please enter a city name');
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      // Use geocoding to find the city
      List<Location> locations = await locationFromAddress(cityName);

      if (locations.isNotEmpty) {
        final foundLocation = locations.first;

        // Get detailed address information
        List<Placemark> placemarks = await placemarkFromCoordinates(
            foundLocation.latitude,
            foundLocation.longitude
        );

        String locationName = cityName;
        String country = 'Unknown';

        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          locationName = placemark.locality ?? placemark.subAdministrativeArea ?? cityName;
          country = placemark.country ?? 'Unknown';
        }

        // Create location model
        final location = LocationModel(
          name: locationName,
          country: country,
          latitude: foundLocation.latitude,
          longitude: foundLocation.longitude,
        );

        // Add a point to the globe for the searched location
        final point = Point(
          id: 'search_result',
          coordinates: GlobeCoordinates(foundLocation.latitude, foundLocation.longitude),
          label: locationName,
          isLabelVisible: true,
          style: const PointStyle(
            color: Colors.red,
            size: 10,
          ),
          onTap: () => _onLocationTapped({
            'name': locationName,
            'country': country,
            'latitude': foundLocation.latitude,
            'longitude': foundLocation.longitude,
          }),
        );

        // Remove previous search result if exists
        try {
          _globeController.removePoint('search_result');
        } catch (e) {
          // Point doesn't exist, that's fine
        }

        // Add new search result point
        _globeController.addPoint(point);

        // Set as selected location and show sheet
        context.read<LocationProvider>().setSelectedLocation(location);
        _showLocationSelectionSheet(location);

        _showSuccessSnackBar('Found: $locationName, $country');
      } else {
        _showErrorSnackBar('City not found. Please try a different name.');
      }
    } catch (e) {
      print('Search error: $e');
      _showErrorSnackBar('Failed to search for city. Please check your internet connection.');
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _globeController.dispose();
    _pulseController.dispose();
    _searchController.dispose();
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
            fontSize: 22,
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
          // Background gradient
          const GradientBackground(),

          // FULL SCREEN Globe with zooming
          Positioned.fill(
            child: GestureDetector(
              onTapDown: (details) {
                final RenderBox renderBox = context.findRenderObject() as RenderBox;
                final localPosition = renderBox.globalToLocal(details.globalPosition);

                // Calculate globe coordinates (more accurate for full screen)
                final centerX = size.width / 2;
                final centerY = size.height / 2;
                final maxRadius = min(size.width, size.height) / 2;

                final dx = localPosition.dx - centerX;
                final dy = localPosition.dy - centerY;
                final distance = sqrt(dx * dx + dy * dy);

                // Check if tap is within globe bounds
                if (distance <= maxRadius) {
                  final lat = (dy / maxRadius) * -90;
                  final lng = (dx / maxRadius) * 180;

                  final clampedLat = lat.clamp(-90.0, 90.0);
                  final clampedLng = lng.clamp(-180.0, 180.0);

                  _onGlobeTapped(GlobeCoordinates(clampedLat, clampedLng));
                }
              },
              child: InteractiveViewer(
                // ADDED: Zooming functionality
                minScale: 0.5,
                maxScale: 3.0,
                boundaryMargin: const EdgeInsets.all(50),
                constrained: true,
                child: Container(
                  width: size.width,
                  height: size.height,
                  child: Stack(
                    children: [
                      // Visual Earth backdrop (full screen)
                      Container(
                        width: size.width,
                        height: size.height,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.center,
                            colors: [
                              Colors.blue[300]!,
                              Colors.blue[600]!,
                              Colors.blue[800]!,
                              Colors.black.withOpacity(0.8),
                            ],
                            stops: const [0.0, 0.4, 0.7, 1.0],
                          ),
                        ),
                        child: CustomPaint(
                          painter: FullScreenEarthPainter(),
                        ),
                      ),

                      // Flutter Earth Globe widget (full screen)
                      if (_isGlobeReady)
                        Positioned.fill(
                          child: FlutterEarthGlobe(
                            controller: _globeController,
                            radius: min(size.width, size.height) / 2,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Loading state
          if (!_isGlobeReady)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
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
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue.withOpacity(0.3),
                                border: Border.all(
                                  color: Colors.blue,
                                  width: 3,
                                ),
                              ),
                              child: const Icon(
                                Icons.public,
                                color: Colors.blue,
                                size: 60,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Loading Earth Globe...',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Instructions overlay
          if (_showInstructions && _isGlobeReady)
            Positioned(
              top: 120,
              left: 20,
              right: 20,
              child: AnimatedOpacity(
                opacity: _showInstructions ? 1.0 : 0.0,
                duration: AppConstants.mediumAnimation,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.touch_app,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Tap anywhere on Earth to select location • Pinch to zoom',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.amber,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Golden dots = popular cities • Red dots = search results',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showInstructions = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Text(
                            'Got it!',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Floating action button with working search
          Positioned(
            bottom: 30,
            right: 20,
            child: FloatingActionButton.extended(
              onPressed: () {
                _showLocationSearchDialog();
              },
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              icon: _isSearching
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Icon(Icons.search),
              label: Text(_isSearching ? 'Searching...' : 'Search Location'),
              elevation: 8,
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Enter city name',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                Navigator.pop(context);
                _searchCity(value);
              },
            ),
            const SizedBox(height: 8),
            const Text(
              'Examples: London, Tokyo, Cairo, Sydney',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _searchCity(_searchController.text);
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
            Text('• Interactive full-screen 3D Earth globe'),
            Text('• Pinch-to-zoom navigation'),
            Text('• City search with geocoding'),
            Text('• Real-time weather analysis'),
            Text('• Event suitability assessment'),
            Text('• Risk predictions and recommendations'),
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

// Custom painter for full-screen Earth appearance
class FullScreenEarthPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2E7D32).withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = min(size.width, size.height) / 2;

    // Draw major continents
    // North America
    canvas.drawCircle(
      Offset(center.dx - maxRadius * 0.3, center.dy - maxRadius * 0.2),
      maxRadius * 0.15,
      paint,
    );

    // Europe/Africa
    canvas.drawCircle(
      Offset(center.dx + maxRadius * 0.1, center.dy - maxRadius * 0.1),
      maxRadius * 0.12,
      paint,
    );

    // Asia
    canvas.drawCircle(
      Offset(center.dx + maxRadius * 0.4, center.dy - maxRadius * 0.15),
      maxRadius * 0.18,
      paint,
    );

    // Australia
    canvas.drawCircle(
      Offset(center.dx + maxRadius * 0.35, center.dy + maxRadius * 0.25),
      maxRadius * 0.06,
      paint,
    );

    // South America
    canvas.drawCircle(
      Offset(center.dx - maxRadius * 0.25, center.dy + maxRadius * 0.3),
      maxRadius * 0.1,
      paint,
    );

    // Add islands scattered around
    for (int i = 0; i < 20; i++) {
      final angle = (i * 18.0) * (pi / 180);
      final islandX = center.dx + (maxRadius * 0.7) * cos(angle);
      final islandY = center.dy + (maxRadius * 0.7) * sin(angle);

      if (islandX >= 0 && islandX <= size.width &&
          islandY >= 0 && islandY <= size.height) {
        canvas.drawCircle(
            Offset(islandX, islandY),
            maxRadius * 0.01,
            paint
        );
      }
    }

    // Add cloud formations
    final cloudPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 15; i++) {
      final angle = (i * 24.0) * (pi / 180);
      final cloudX = center.dx + (maxRadius * 0.8) * cos(angle);
      final cloudY = center.dy + (maxRadius * 0.8) * sin(angle);

      if (cloudX >= 0 && cloudX <= size.width &&
          cloudY >= 0 && cloudY <= size.height) {
        canvas.drawCircle(
            Offset(cloudX, cloudY),
            maxRadius * 0.03,
            cloudPaint
        );
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}