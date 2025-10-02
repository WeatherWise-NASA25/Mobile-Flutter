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
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Consumer<WeatherProvider>(
        builder: (context, weatherProvider, child) {
          final WeatherAnalysis? analysis = weatherProvider.currentAnalysis;

          if (analysis == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                _buildSliverAppBar(analysis),
                SliverToBoxAdapter(
                  child: _buildHeaderCard(analysis),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: Theme.of(context).colorScheme.primary,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Theme.of(context).colorScheme.primary,
                      labelPadding: EdgeInsets.symmetric(
                        horizontal: screenWidth > 400 ? 16 : 8,
                      ),
                      tabs: [
                        Tab(
                          text: screenWidth > 400 ? 'Forecast' : null,
                          icon: const Icon(Icons.wb_sunny, size: 20),
                          // child: screenWidth <= 400
                          //     ? const Icon(Icons.wb_sunny, size: 20)
                          //     : null,
                        ),
                        Tab(
                          text: screenWidth > 400 ? 'History' : null,
                          icon: const Icon(Icons.history, size: 20),
                          // child: screenWidth <= 400
                          //     ? const Icon(Icons.history, size: 20)
                          //     : null,
                        ),
                        Tab(
                          text: screenWidth > 400 ? 'Risks' : null,
                          icon: const Icon(Icons.warning, size: 20),
                          // child: screenWidth <= 400
                          //     ? const Icon(Icons.warning, size: 20)
                          //     : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildForecastTab(analysis),
                _buildHistoryTab(analysis),
                _buildRisksTab(analysis),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: FloatingActionButton.extended(
          onPressed: _exportData,
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.download),
          label: const Text('Export CSV'),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(WeatherAnalysis analysis) {
    final screenWidth = MediaQuery.of(context).size.width;

    return SliverAppBar(
      expandedHeight: screenWidth > 400 ? 120.0 : 100.0,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(
          left: screenWidth > 400 ? 60 : 50,
          bottom: 16,
        ),
        title: Text(
          'Weather Analysis',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontWeight: FontWeight.bold,
            fontSize: screenWidth > 400 ? 20 : 16,
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
    final screenWidth = MediaQuery.of(context).size.width;

    return AnimatedBuilder(
      animation: _headerAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _headerAnimation.value,
          child: Container(
            margin: EdgeInsets.all(screenWidth > 400 ? 16 : 12),
            padding: EdgeInsets.all(screenWidth > 400 ? 20 : 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getRiskColor(analysis.riskAssessment.overallRisk),
                  _getRiskColor(analysis.riskAssessment.overallRisk)
                      .withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _getRiskColor(analysis.riskAssessment.overallRisk)
                      .withOpacity(0.3),
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
                              fontSize: screenWidth > 400 ? 24 : 18,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('EEEE, MMMM d, y').format(widget.eventDate),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.white70,
                              fontSize: screenWidth > 400 ? 16 : 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            widget.eventType,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                              fontSize: screenWidth > 400 ? 14 : 12,
                            ),
                            overflow: TextOverflow.ellipsis,
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
                        style: TextStyle(
                          fontSize: screenWidth > 400 ? 32 : 24,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenWidth > 400 ? 20 : 16),
                _buildQuickStatsSection(analysis, screenWidth),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickStatsSection(WeatherAnalysis analysis, double screenWidth) {
    final stats = [
      _QuickStatData(
        'Suitability',
        analysis.formattedSuitabilityScore,
        Icons.check_circle,
      ),
      _QuickStatData(
        'Temperature',
        analysis.forecast.formattedTemperature,
        Icons.thermostat,
      ),
      _QuickStatData(
        'Rain Risk',
        '${(analysis.riskAssessment.precipitationRisk * 100).round()}%',
        Icons.water_drop,
      ),
    ];

    if (screenWidth < 400) {
      return Wrap(
        alignment: WrapAlignment.spaceEvenly,
        spacing: 16,
        runSpacing: 12,
        children: stats
            .map((stat) => _buildQuickStat(stat.label, stat.value, stat.icon))
            .toList(),
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: stats
            .map((stat) => _buildQuickStat(stat.label, stat.value, stat.icon))
            .toList(),
      );
    }
  }

  Widget _buildQuickStat(String label, String value, IconData icon) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        Icon(icon, color: Colors.white, size: screenWidth > 400 ? 24 : 20),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: screenWidth > 400 ? 18 : 16,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: screenWidth > 400 ? 12 : 10,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildForecastTab(WeatherAnalysis analysis) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 100),
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
    final screenWidth = MediaQuery.of(context).size.width;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(screenWidth > 400 ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Event Day Forecast',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: screenWidth > 400 ? 22 : 18,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  weather.icon,
                  style: TextStyle(
                    fontSize: screenWidth > 400 ? 48 : 36,
                  ),
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
                          fontSize: screenWidth > 400 ? 32 : 24,
                        ),
                      ),
                      Text(
                        weather.description,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: screenWidth > 400 ? 16 : 14,
                        ),
                        overflow: TextOverflow.ellipsis,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        // Dynamic crossAxisCount: 3 for large/tablet, 2 for phones
        final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;

        // Adjusted aspect ratio: increased vertical space for smaller screens to prevent overflow
        // Base width / (crossAxisCount * factor). Lower factor means taller items.
        final aspectRatio = constraints.maxWidth / (crossAxisCount * (constraints.maxWidth > 400 ? 90 : 100));

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: aspectRatio,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            _buildWeatherDetail(Icons.water_drop, 'Precipitation', weather.formattedPrecipitation),
            _buildWeatherDetail(Icons.air, 'Wind Speed', weather.formattedWindSpeed),
            _buildWeatherDetail(Icons.opacity, 'Humidity', weather.formattedHumidity),
            _buildWeatherDetail(Icons.cloud, 'Cloud Cover', weather.formattedCloudCover),
            _buildWeatherDetail(Icons.compress, 'Pressure', weather.formattedPressure),
            _buildWeatherDetail(Icons.visibility, 'Visibility', weather.formattedVisibility),
          ],
        );
      },
    );
  }

  Widget _buildWeatherDetail(IconData icon, String label, String value) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Reverted to Row-based layout to align icon and text horizontally, saving vertical space.
    return Container(
      padding: EdgeInsets.all(screenWidth > 400 ? 12 : 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row( // Changed from Column back to Row
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon is now on the left
          Icon(
            icon,
            size: screenWidth > 400 ? 20 : 18,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),

          // Text content takes the rest of the space
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    // Slightly reduced font size for mobile
                    fontSize: screenWidth > 400 ? 16 : 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: TextStyle(
                    // Slightly reduced font size for mobile
                    fontSize: screenWidth > 400 ? 12 : 10,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1, // Crucial for label on small cards
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
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 100),
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
    if (historicalData.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text('No historical data available'),
          ),
        ),
      );
    }

    final avgTemp = historicalData.map((d) => d.temperature).reduce((a, b) => a + b) / historicalData.length;
    final avgPrecip = historicalData.map((d) => d.precipitation).reduce((a, b) => a + b) / historicalData.length;
    final avgHumidity = historicalData.map((d) => d.humidity).reduce((a, b) => a + b) / historicalData.length;
    final avgWind = historicalData.map((d) => d.windSpeed).reduce((a, b) => a + b) / historicalData.length;

    final screenWidth = MediaQuery.of(context).size.width;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(screenWidth > 400 ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historical Averages (Last 10 Years)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: screenWidth > 400 ? 20 : 18,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        // Dynamic crossAxisCount for responsiveness
        final crossAxisCount = constraints.maxWidth > 600
            ? 4
            : 2;

        // Adjusted aspect ratio: increased vertical space for smaller screens to prevent overflow
        final aspectRatio = constraints.maxWidth / (crossAxisCount * (constraints.maxWidth > 400 ? 90 : 100));

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: aspectRatio,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            _buildWeatherDetail(Icons.thermostat, 'Avg Temperature', '${avgTemp.round()}°C'),
            _buildWeatherDetail(Icons.water_drop, 'Avg Precipitation', '${avgPrecip.toStringAsFixed(1)}mm'),
            _buildWeatherDetail(Icons.opacity, 'Avg Humidity', '${avgHumidity.round()}%'),
            _buildWeatherDetail(Icons.air, 'Avg Wind Speed', '${avgWind.round()} km/h'),
          ],
        );
      },
    );
  }

  Widget _buildRisksTab(WeatherAnalysis analysis) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 100),
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
    if (risk <= 0.3) return Colors.green.shade600;
    if (risk <= 0.6) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  Future<void> _exportData() async {
    final weatherProvider = context.read<WeatherProvider>();
    final analysis = weatherProvider.currentAnalysis;
    if (analysis == null) return;

    try {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Storage permission denied. Cannot export data.'),
            ),
          );
        }
        return;
      }

      final directory = await getExternalStorageDirectory();
      final exportDirectory = directory ?? await getApplicationDocumentsDirectory();

      if (!await exportDirectory.exists()) {
        await exportDirectory.create(recursive: true);
      }

      final fileName = 'weather_analysis_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final filePath = '${exportDirectory.path}/$fileName';
      final file = File(filePath);

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
            content: Text('Data exported to: $filePath'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Refreshing analysis...'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}

class _QuickStatData {
  final String label;
  final String value;
  final IconData icon;

  _QuickStatData(this.label, this.value, this.icon);
}