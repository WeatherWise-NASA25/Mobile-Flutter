import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_earth_globe/flutter_earth_globe.dart';
import 'package:flutter_earth_globe/flutter_earth_globe_controller.dart';
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

    // Setup globe appearance after build
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

  void _setupGlobeAppearance() async {
    try {
      // Load Earth day texture
      await _globeController.loadSurfaceImages();
      
      // Load star field background
      await _globeController.loadBackground(
        const AssetImage('assets/images/stars.jpg'),
        followsRotation: true,
      );

      // Customize sphere style
      _globeController.changeSphereStyle(
        SphereStyle(
          shadowColor: Colors.black.withOpacity(0.4),
          shadowBlurSigma: 20,
        ),
      );

      // Add sample location points
      _addSampleLocationPoints();

      setState(() {
        _isGlobeReady = true;
      });
    } catch (e) {
      print('Error setting up globe: $e');
      setState(() {
        _isGlobeReady = true; // Show even if textures fail to load
      });
    }
  }

  void _addSampleLocationPoints() {
    for (int i = 0; i < AppConstants.sampleLocations.length; i++) {
      final location = AppConstants.sampleLocations[i];
      
      _globeController.addPoint(
        Point(
          id: 'location_$i',
          coordinates: GlobeCoordinates(
            location['latitude']!,
            location['longitude']!,
          ),
          label: location['name']!,
          isLabelVisible: false,
          style: PointStyle(
            color: Colors.amber,
            size: 6,
          ),
          onTap: () => _onLocationTapped(location),
          onHover: () => _onLocationHovered(location),
        ),
      );
    }
  }

  void _onLocationTapped(Map<String, dynamic> locationData) {
    HapticFeedback.lightImpact();
    
    final location = LocationModel(
      name: locationData['name']!,
      country: locationData['country']!,
      latitude: locationData['latitude']!,
      longitude: locationData['longitude']!,
      timezone: locationData['timezone'],
    );

    context.read<LocationProvider>().setSelectedLocation(location);
    _showLocationSelectionSheet(location);
  }

  void _onLocationHovered(Map<String, dynamic> locationData) {
    // Show temporary label or highlight
    setState(() {
      // Update UI to show location name briefly
    });
  }

  void _onGlobeTapped(GlobeCoordinates coordinates) {
    HapticFeedback.mediumImpact();
    
    // Create location from coordinates
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
    _globeController.animateToCoordinates(
      GlobeCoordinates(0, 0),
      duration: const Duration(seconds: 2),
    );
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
          // Gradient background
          const GradientBackground(),
          
          // 3D Earth Globe
          if (_isGlobeReady)
            Positioned.fill(
              child: GestureDetector(
                onTapDown: (details) {
                  // Convert screen coordinates to globe coordinates
                  final RenderBox renderBox = context.findRenderObject() as RenderBox;
                  final localPosition = renderBox.globalToLocal(details.globalPosition);
                  
                  // Calculate globe coordinates (this is a simplified calculation)
                  final centerX = size.width / 2;
                  final centerY = size.height / 2;
                  final radius = 150.0; // Globe radius
                  
                  final dx = localPosition.dx - centerX;
                  final dy = localPosition.dy - centerY;
                  final distance = (dx * dx + dy * dy).abs();
                  
                  // Check if tap is within globe
                  if (distance <= radius * radius) {
                    // Convert to lat/lng (simplified)
                    final lat = (dy / radius) * 90;
                    final lng = (dx / radius) * 180;
                    _onGlobeTapped(GlobeCoordinates(lat.clamp(-90, 90), lng.clamp(-180, 180)));
                  }
                },
                child: FlutterEarthGlobe(
                  controller: _globeController,
                  radius: 150,
                ),
              ),
            )
          else
            // Loading state
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

          // Floating action button for manual location search
          Positioned(
            bottom: 30,
            right: 20,
            child: FloatingActionButton.extended(
              onPressed: () {
                // TODO: Implement location search
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
              // TODO: Implement search functionality
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