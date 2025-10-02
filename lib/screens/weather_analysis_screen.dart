import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/location_model.dart';
import '../models/weather_model.dart';
import '../providers/weather_provider.dart';
import '../widgets/weather_chart.dart';
import '../widgets/risk_assessment_card.dart';
import '../widgets/recommendations_card.dart';
import '../utils/constants.dart';

class WeatherAnalysisScreen extends StatefulWidget {
  final LocationModel location;
  final DateTime eventDate;
  final String eventType;

  const WeatherAnalysisScreen({
    super.key,
    required this.location,
    required this.eventDate,
    required this.eventType,
  });

  @override
  State<WeatherAnalysisScreen> createState() => _WeatherAnalysisScreenState();
}

class _WeatherAnalysisScreenState extends State<WeatherAnalysisScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _headerAnimationController;
  late Animation<double> _headerAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _tabController = TabController(length: 3, vsync: this);
    
    _headerAnimationController = AnimationController(
      duration: AppConstants.mediumAnimation,
      vsync: this,
    );

    _headerAnimation = CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOut,
    );

    _headerAnimationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headerAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<WeatherProvider>(
        builder: (context, weatherProvider, child) {
          final analysis = weatherProvider.currentAnalysis;
          
          if (analysis == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(analysis),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildHeaderCard(analysis),
                    _buildTabContent(analysis),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _exportData,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.download),
        label: const Text('Export CSV'),
      ),
    );
  }

  Widget _buildSliverAppBar(WeatherAnalysis analysis) {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Weather Analysis',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primaryContainer,
                Theme.of(context).colorScheme.surface,
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: _shareAnalysis,
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => _refreshAnalysis(),
        ),
      ],
    );
  }

  Widget _buildHeaderCard(WeatherAnalysis analysis) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _headerAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _headerAnimation.value,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getRiskColor(analysis.riskAssessment.overallRisk),
                  _getRiskColor(analysis.riskAssessment.overallRisk).withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _getRiskColor(analysis.riskAssessment.overallRisk).withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.location.displayName,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('EEEE, MMMM d, y').format(widget.eventDate),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            widget.eventType,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        analysis.forecast.icon,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildQuickStat(
                      'Suitability',
                      analysis.formattedSuitabilityScore,
                      Icons.check_circle,
                    ),
                    _buildQuickStat(
                      'Temperature',
                      analysis.forecast.formattedTemperature,
                      Icons.thermostat,
                    ),
                    _buildQuickStat(
                      'Rain Risk',
                      '${(analysis.riskAssessment.precipitationRisk * 100).round()}%',
                      Icons.water_drop,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent(WeatherAnalysis analysis) {
    return Container(
      height: 600, // Fixed height for tab content
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: const [
              Tab(text: 'Forecast', icon: Icon(Icons.wb_sunny)),
              Tab(text: 'History', icon: Icon(Icons.history)),
              Tab(text: 'Risks', icon: Icon(Icons.warning)),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildForecastTab(analysis),
                _buildHistoryTab(analysis),
                _buildRisksTab(analysis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastTab(WeatherAnalysis analysis) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCurrentWeatherCard(analysis.forecast),
          const SizedBox(height: 16),
          RecommendationsCard(
            recommendations: analysis.recommendations,
            riskLevel: analysis.riskLevel,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentWeatherCard(WeatherData weather) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Event Day Forecast',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  weather.icon,
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        weather.formattedTemperature,
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        weather.description,
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildWeatherDetailsGrid(weather),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetailsGrid(WeatherData weather) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.5,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildWeatherDetail(Icons.water_drop, 'Precipitation', weather.formattedPrecipitation),
        _buildWeatherDetail(Icons.air, 'Wind Speed', weather.formattedWindSpeed),
        _buildWeatherDetail(Icons.opacity, 'Humidity', weather.formattedHumidity),
        _buildWeatherDetail(Icons.cloud, 'Cloud Cover', weather.formattedCloudCover),
        _buildWeatherDetail(Icons.compress, 'Pressure', weather.formattedPressure),
        _buildWeatherDetail(Icons.visibility, 'Visibility', weather.formattedVisibility),
      ],
    );
  }

  Widget _buildWeatherDetail(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(WeatherAnalysis analysis) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          WeatherChart(
            historicalData: analysis.historicalData,
            forecast: analysis.forecast,
          ),
          const SizedBox(height: 16),
          _buildHistoricalStatsCard(analysis.historicalData),
        ],
      ),
    );
  }

  Widget _buildHistoricalStatsCard(List<WeatherData> historicalData) {
    final avgTemp = historicalData.map((d) => d.temperature).reduce((a, b) => a + b) / historicalData.length;
    final avgPrecip = historicalData.map((d) => d.precipitation).reduce((a, b) => a + b) / historicalData.length;
    final avgHumidity = historicalData.map((d) => d.humidity).reduce((a, b) => a + b) / historicalData.length;
    final avgWind = historicalData.map((d) => d.windSpeed).reduce((a, b) => a + b) / historicalData.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historical Averages (Last 10 Years)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildHistoricalStatsGrid(avgTemp, avgPrecip, avgHumidity, avgWind),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoricalStatsGrid(double avgTemp, double avgPrecip, double avgHumidity, double avgWind) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.5,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildWeatherDetail(Icons.thermostat, 'Avg Temperature', '${avgTemp.round()}°C'),
        _buildWeatherDetail(Icons.water_drop, 'Avg Precipitation', '${avgPrecip.toStringAsFixed(1)}mm'),
        _buildWeatherDetail(Icons.opacity, 'Avg Humidity', '${avgHumidity.round()}%'),
        _buildWeatherDetail(Icons.air, 'Avg Wind Speed', '${avgWind.round()} km/h'),
      ],
    );
  }

  Widget _buildRisksTab(WeatherAnalysis analysis) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          RiskAssessmentCard(
            riskAssessment: analysis.riskAssessment,
            eventType: widget.eventType,
          ),
          const SizedBox(height: 16),
          RecommendationsCard(
            recommendations: analysis.recommendations,
            riskLevel: analysis.riskLevel,
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(double risk) {
    if (risk <= 0.3) return Colors.green;
    if (risk <= 0.6) return Colors.orange;
    return Colors.red;
  }

  Future<void> _exportData() async {
    final weatherProvider = context.read<WeatherProvider>();
    final analysis = weatherProvider.currentAnalysis;
    
    if (analysis == null) return;

    try {
      // Check storage permission
      if (await Permission.storage.isDenied) {
        await Permission.storage.request();
      }

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'weather_analysis_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${directory.path}/$fileName');

      // Prepare CSV data
      final csvData = [
        ['Weather Analysis Report'],
        ['Location', analysis.location.displayName],
        ['Event Date', DateFormat('yyyy-MM-dd HH:mm').format(analysis.eventDate)],
        ['Event Type', analysis.eventType],
        ['Suitability Score', analysis.formattedSuitabilityScore],
        ['Analysis Date', DateFormat('yyyy-MM-dd HH:mm').format(analysis.analyzedAt)],
        [''],
        ['Forecast Data'],
        ['Temperature (°C)', analysis.forecast.temperature.toString()],
        ['Humidity (%)', analysis.forecast.humidity.toString()],
        ['Precipitation (mm)', analysis.forecast.precipitation.toString()],
        ['Wind Speed (km/h)', analysis.forecast.windSpeed.toString()],
        ['Cloud Cover (%)', analysis.forecast.cloudCover.toString()],
        ['Pressure (hPa)', analysis.forecast.pressure.toString()],
        ['Visibility (km)', analysis.forecast.visibility.toString()],
        [''],
        ['Risk Assessment'],
        ['Overall Risk', (analysis.riskAssessment.overallRisk * 100).toStringAsFixed(1) + '%'],
        ['Precipitation Risk', (analysis.riskAssessment.precipitationRisk * 100).toStringAsFixed(1) + '%'],
        ['Temperature Risk', (analysis.riskAssessment.temperatureRisk * 100).toStringAsFixed(1) + '%'],
        ['Wind Risk', (analysis.riskAssessment.windRisk * 100).toStringAsFixed(1) + '%'],
        ['Visibility Risk', (analysis.riskAssessment.visibilityRisk * 100).toStringAsFixed(1) + '%'],
        [''],
        ['Recommendations'],
        ...analysis.recommendations.map((rec) => [rec]),
        [''],
        ['Historical Data (Last 10 Years)'],
        ['Year', 'Temperature (°C)', 'Precipitation (mm)', 'Humidity (%)', 'Wind Speed (km/h)'],
        ...analysis.historicalData.map((data) => [
          data.date.year.toString(),
          data.temperature.toStringAsFixed(1),
          data.precipitation.toStringAsFixed(1),
          data.humidity.toStringAsFixed(1),
          data.windSpeed.toStringAsFixed(1),
        ]),
      ];

      final csvString = const ListToCsvConverter().convert(csvData);
      await file.writeAsString(csvString);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data exported to: ${file.path}'),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () {
                // TODO: Open file with external app
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _shareAnalysis() {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality coming soon!'),
      ),
    );
  }

  void _refreshAnalysis() {
    final weatherProvider = context.read<WeatherProvider>();
    weatherProvider.analyzeWeatherForEvent(
      location: widget.location,
      eventDate: widget.eventDate,
      eventType: widget.eventType,
    );
  }
}