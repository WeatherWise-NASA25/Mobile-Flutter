import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/location_model.dart';
import '../models/weather_model.dart';
import '../providers/weather_provider.dart';
import '../screens/weather_analysis_screen.dart' show WeatherAnalysisScreen;
import '../utils/constants.dart';

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

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setDefaultDateTime();
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
    _selectedTime = TimeOfDay(hour: 14, minute: 0); // 2 PM default
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
            Expanded(
              child: GridView.builder(
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
      // Combine date and time
      final eventDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final weatherProvider = context.read<WeatherProvider>();
      
      await weatherProvider.analyzeWeatherForEvent(
        location: widget.location,
        eventDate: eventDateTime,
        eventType: _selectedEventType!,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                WeatherAnalysisScreen(
              location: widget.location,
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
    final size = MediaQuery.of(context).size;

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
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Location Info
                          _buildLocationHeader(),
                          const SizedBox(height: 24),

                          // Event Planning Section
                          Text(
                            'Plan Your Event',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Date Selection
                          _buildDateTimeSelectors(),
                          const SizedBox(height: 16),

                          // Event Type Selection
                          _buildEventTypeSelector(),
                          const SizedBox(height: 32),

                          // Analyze Button
                          _buildAnalyzeButton(),
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

  Widget _buildLocationHeader() {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
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
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.location.displayName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Coordinates: ${widget.location.coordinates}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          if (widget.location.timezone != null)
            Text(
              'Timezone: ${widget.location.timezone}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSelectors() {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Expanded(
          child: _buildSelectorCard(
            icon: Icons.calendar_today,
            title: 'Date',
            subtitle: _selectedDate?.formattedDate ?? 'Select date',
            onTap: _selectDate,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSelectorCard(
            icon: Icons.access_time,
            title: 'Time',
            subtitle: _selectedTime?.format(context) ?? 'Select time',
            onTap: _selectTime,
          ),
        ),
      ],
    );
  }

  Widget _buildEventTypeSelector() {
    return _buildSelectorCard(
      icon: AppConstants.eventIcons[_selectedEventType] ?? Icons.event,
      title: 'Event Type',
      subtitle: _selectedEventType ?? 'Select event type',
      onTap: _selectEventType,
      fullWidth: true,
    );
  }

  Widget _buildSelectorCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool fullWidth = false,
  }) {
    final theme = Theme.of(context);
    final isSelected = subtitle != 'Select date' && 
                      subtitle != 'Select time' && 
                      subtitle != 'Select event type';
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzeButton() {
    final theme = Theme.of(context);
    final canAnalyze = _selectedDate != null && 
                      _selectedTime != null && 
                      _selectedEventType != null;
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: canAnalyze && !_isAnalyzing ? _analyzeWeather : null,
        icon: _isAnalyzing
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.onPrimary,
                  ),
                ),
              )
            : const Icon(Icons.analytics),
        label: Text(
          _isAnalyzing 
              ? 'Analyzing Weather...'
              : 'Analyze Event Suitability',
          style: const TextStyle(
            fontSize: 16,
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