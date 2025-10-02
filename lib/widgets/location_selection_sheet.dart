import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:weatherwise/screens/weather_analysis_screen.dart';
import '../models/location_model.dart';
import '../models/weather_model.dart';
import '../providers/weather_provider.dart';
import '../utils/constants.dart';
import 'package:geocoding/geocoding.dart';

class LocationSelectionSheet extends StatefulWidget {
  final LocationModel location;

  const LocationSelectionSheet({
    super.key,
    required this.location,
  });

  @override
  State<LocationSelectionSheet> createState() => _LocationSelectionSheetState();
}

class _LocationSelectionSheetState extends State<LocationSelectionSheet>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedEventType;
  bool _isAnalyzing = false;
  bool _isLoadingLocationName = false;
  String _locationDisplayName = '';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setDefaultDateTime();
    _loadLocationName();
  }

  void _setupAnimations() {
    _slideController = AnimationController(
      duration: AppConstants.mediumAnimation,
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: AppConstants.shortAnimation,
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_fadeController);

    _slideController.forward();
    _fadeController.forward();
  }

  void _setDefaultDateTime() {
    final now = DateTime.now();
    _selectedDate = now.add(const Duration(days: 1));
    _selectedTime = const TimeOfDay(hour: 14, minute: 0);
  }

  void _loadLocationName() async {
    if (widget.location.name != 'Custom Location') {
      setState(() {
        _locationDisplayName = widget.location.displayName;
      });
      return;
    }

    setState(() {
      _isLoadingLocationName = true;
      _locationDisplayName = 'Loading location...';
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        widget.location.latitude,
        widget.location.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final locationName = _formatLocationName(placemark);

        setState(() {
          _locationDisplayName = locationName;
          _isLoadingLocationName = false;
        });
      } else {
        setState(() {
          _locationDisplayName = 'Unknown Location';
          _isLoadingLocationName = false;
        });
      }
    } catch (e) {
      setState(() {
        _locationDisplayName = 'Location (${widget.location.coordinates})';
        _isLoadingLocationName = false;
      });
    }
  }

  String _formatLocationName(Placemark placemark) {
    List<String> parts = [];

    if (placemark.locality?.isNotEmpty ?? false) {
      parts.add(placemark.locality!);
    } else if (placemark.subAdministrativeArea?.isNotEmpty ?? false) {
      parts.add(placemark.subAdministrativeArea!);
    } else if (placemark.administrativeArea?.isNotEmpty ?? false) {
      parts.add(placemark.administrativeArea!);
    }

    if (placemark.country?.isNotEmpty ?? false) {
      parts.add(placemark.country!);
    }

    return parts.isNotEmpty ? parts.join(', ') : 'Unknown Location';
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
            dialogBackgroundColor: Theme.of(context).cardColor,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 14, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _selectEventType() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Select Event Type',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: AppConstants.eventTypes.length,
                itemBuilder: (context, index) {
                  final eventType = AppConstants.eventTypes[index];
                  final icon = AppConstants.eventIcons[eventType] ?? Icons.event;
                  final isSelected = _selectedEventType == eventType;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedEventType = eventType;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icon,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[600],
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            eventType,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _analyzeWeather() async {
    if (_selectedDate == null ||
        _selectedTime == null ||
        _selectedEventType == null) {
      _showValidationError();
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    HapticFeedback.lightImpact();

    try {
      final eventDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final weatherProvider = context.read<WeatherProvider>();

      final updatedLocation = widget.location.copyWith(
        name: _locationDisplayName.split(',').first,
        country: _locationDisplayName.contains(',')
            ? _locationDisplayName.split(',').last.trim()
            : 'Unknown',
      );

      await weatherProvider.analyzeWeatherForEvent(
        location: updatedLocation,
        eventDate: eventDateTime,
        eventType: _selectedEventType!,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                WeatherAnalysisScreen(
                  location: updatedLocation,
                  eventDate: eventDateTime,
                  eventType: _selectedEventType!,
                ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                )),
                child: child,
              );
            },
            transitionDuration: AppConstants.mediumAnimation,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        _showErrorDialog(error.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  void _showValidationError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Please select date, time, and event type'),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Analysis Error'),
        content: Text('Failed to analyze weather data: $error'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: EdgeInsets.all(screenWidth * 0.05), // Responsive padding
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Location Info
                          _buildLocationHeader(screenWidth),
                          SizedBox(height: screenHeight * 0.03),

                          // Event Planning Section
                          Text(
                            'Plan Your Event',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: screenWidth * 0.06, // Responsive font
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.02),

                          // Date and Time Selection - FIXED RESPONSIVE
                          _buildDateTimeSelectors(screenWidth, screenHeight),
                          SizedBox(height: screenHeight * 0.02),

                          // Event Type Selection
                          _buildEventTypeSelector(screenWidth, screenHeight),
                          SizedBox(height: screenHeight * 0.04),

                          // Analyze Button
                          _buildAnalyzeButton(screenWidth, screenHeight),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLocationHeader(double screenWidth) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.primaryContainer.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: theme.colorScheme.primary,
                size: screenWidth * 0.06,
              ),
              SizedBox(width: screenWidth * 0.02),
              Expanded(
                child: _isLoadingLocationName
                    ? Row(
                  children: [
                    SizedBox(
                      width: screenWidth * 0.04,
                      height: screenWidth * 0.04,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    Flexible(
                      child: Text(
                        'Loading location...',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth * 0.045,
                        ),
                      ),
                    ),
                  ],
                )
                    : Text(
                  _locationDisplayName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.045,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screenWidth * 0.02),
          Text(
            'Coordinates: ${widget.location.coordinates}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
              fontSize: screenWidth * 0.035,
            ),
          ),
          if (widget.location.timezone != null)
            Text(
              'Timezone: ${widget.location.timezone}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                fontSize: screenWidth * 0.035,
              ),
            ),
        ],
      ),
    );
  }

  // FIXED: Responsive Date and Time selectors with same height
  Widget _buildDateTimeSelectors(double screenWidth, double screenHeight) {
    return Row(
      children: [
        Expanded(
          child: _buildSelectorCard(
            icon: Icons.calendar_today,
            title: 'Date',
            subtitle: _selectedDate?.formattedDate ?? 'Select date',
            onTap: _selectDate,
            screenWidth: screenWidth,
            screenHeight: screenHeight,
          ),
        ),
        SizedBox(width: screenWidth * 0.03),
        Expanded(
          child: _buildSelectorCard(
            icon: Icons.access_time,
            title: 'Time',
            subtitle: _selectedTime?.format(context) ?? 'Select time',
            onTap: _selectTime,
            screenWidth: screenWidth,
            screenHeight: screenHeight,
          ),
        ),
      ],
    );
  }

  Widget _buildEventTypeSelector(double screenWidth, double screenHeight) {
    return _buildSelectorCard(
      icon: AppConstants.eventIcons[_selectedEventType] ?? Icons.event,
      title: 'Event Type',
      subtitle: _selectedEventType ?? 'Select event type',
      onTap: _selectEventType,
      fullWidth: true,
      screenWidth: screenWidth,
      screenHeight: screenHeight,
    );
  }

  // FIXED: Responsive selector card with consistent height
  Widget _buildSelectorCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool fullWidth = false,
    required double screenWidth,
    required double screenHeight,
  }) {
    final theme = Theme.of(context);
    final isSelected = subtitle != 'Select date' &&
        subtitle != 'Select time' &&
        subtitle != 'Select event type';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: screenHeight * 0.1, // FIXED: Consistent height
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer.withOpacity(0.3)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.5)
                : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? theme.colorScheme.primary
                  : Colors.grey[600],
              size: screenWidth * 0.06,
            ),
            SizedBox(width: screenWidth * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center, // FIXED: Center content
                children: [
                  Text(
                    title,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.grey[600],
                      fontSize: screenWidth * 0.035,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: screenWidth * 0.04,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.textTheme.bodyLarge?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: screenWidth * 0.05,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzeButton(double screenWidth, double screenHeight) {
    final theme = Theme.of(context);
    final canAnalyze = _selectedDate != null &&
        _selectedTime != null &&
        _selectedEventType != null &&
        !_isLoadingLocationName;

    return SizedBox(
      width: double.infinity,
      height: screenHeight * 0.07, // Responsive height
      child: FilledButton.icon(
        onPressed: canAnalyze && !_isAnalyzing ? _analyzeWeather : null,
        icon: _isAnalyzing
            ? SizedBox(
          width: screenWidth * 0.05,
          height: screenWidth * 0.05,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.onPrimary,
            ),
          ),
        )
            : Icon(Icons.analytics, size: screenWidth * 0.05),
        label: Text(
          _isAnalyzing
              ? 'Analyzing Weather...'
              : 'Analyze Event Suitability',
          style: TextStyle(
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: canAnalyze
              ? theme.colorScheme.primary
              : Colors.grey[400],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}