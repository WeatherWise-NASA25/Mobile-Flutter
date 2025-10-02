import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/weather_model.dart';

class WeatherChart extends StatefulWidget {
  final List<WeatherData> historicalData;
  final WeatherData forecast;

  const WeatherChart({
    super.key,
    required this.historicalData,
    required this.forecast,
  });

  @override
  State<WeatherChart> createState() => _WeatherChartState();
}

class _WeatherChartState extends State<WeatherChart> {
  int _selectedMetric = 0; // 0: Temperature, 1: Precipitation, 2: Humidity

  final List<String> _metrics = ['Temperature', 'Precipitation', 'Humidity'];
  final List<IconData> _metricIcons = [
    Icons.thermostat,
    Icons.water_drop,
    Icons.opacity,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historical Trends',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // FIX: Use SingleChildScrollView with a Row for horizontal scrolling
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              // Apply padding only to the right of the entire scroll view
              padding: const EdgeInsets.only(right: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: List.generate(_metrics.length, (index) {
                  final isSelected = _selectedMetric == index;
                  // Space between buttons, applied to the right of every item except the last one
                  final horizontalSpacing = index < _metrics.length - 1 ? 8.0 : 0.0;

                  return Padding(
                    padding: EdgeInsets.only(right: horizontalSpacing),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedMetric = index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _metricIcons[index],
                              size: 16,
                              color: isSelected
                                  ? Colors.white
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _metrics[index],
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : theme.colorScheme.onSurfaceVariant,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 20),

            // Responsive Chart Height using LayoutBuilder
            LayoutBuilder(
              builder: (context, constraints) {
                // Height is based on a factor of available width, clamped to a reasonable range
                final height = constraints.maxWidth * 0.6;
                return SizedBox(
                  // Min height of 180 and Max height of 300
                  height: height.clamp(180.0, 300.0),
                  child: LineChart(
                    _buildChartData(screenWidth),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Legend
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  LineChartData _buildChartData(double screenWidth) {
    final theme = Theme.of(context);

    // Prepare data points
    final historicalSpots = <FlSpot>[];
    for (int i = 0; i < widget.historicalData.length; i++) {
      final data = widget.historicalData[i];
      final value = _getMetricValue(data, _selectedMetric);
      historicalSpots.add(FlSpot(i.toDouble(), value));
    }

    // Add forecast point
    final forecastValue = _getMetricValue(widget.forecast, _selectedMetric);
    final forecastSpot = FlSpot(widget.historicalData.length.toDouble(), forecastValue);

    // Responsive reserved size for Y-Axis titles to prevent overlap
    final yAxisReservedSize = screenWidth < 350 ? 30.0 : 42.0;
    final axisFontSize = screenWidth < 350 ? 8.0 : 10.0;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: _getInterval(_selectedMetric),
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey[300]!,
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: Colors.grey[300]!,
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (double value, TitleMeta meta) {
              if (value.toInt() < widget.historicalData.length) {
                // This assumes your WeatherData model has a DateTime property named 'date'
                // and historicalData is chronologically ordered.
                final year = widget.historicalData[value.toInt()].date.year;
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    year.toString().substring(2), // Show last 2 digits of year
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                      fontSize: axisFontSize, // Responsive font size
                    ),
                  ),
                );
              } else if (value.toInt() == widget.historicalData.length) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    'Now',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: axisFontSize, // Responsive font size
                    ),
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: _getInterval(_selectedMetric),
            reservedSize: yAxisReservedSize, // Responsive reserved size
            getTitlesWidget: (double value, TitleMeta meta) {
              return Text(
                _formatYAxisLabel(value, _selectedMetric),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  fontSize: axisFontSize, // Responsive font size
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      minX: 0,
      maxX: widget.historicalData.length.toDouble(),
      minY: _getMinY(_selectedMetric),
      maxY: _getMaxY(_selectedMetric),
      lineBarsData: [
        // Historical data line
        LineChartBarData(
          spots: historicalSpots,
          isCurved: true,
          gradient: LinearGradient(
            colors: [
              Colors.blue.withOpacity(0.8),
              Colors.blue.withOpacity(0.3),
            ],
          ),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 3,
                color: Colors.blue,
                strokeWidth: 1,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                Colors.blue.withOpacity(0.1),
                Colors.blue.withOpacity(0.05),
              ],
            ),
          ),
        ),

        // Forecast point
        LineChartBarData(
          spots: [forecastSpot],
          isCurved: false,
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary,
            ],
          ),
          barWidth: 4,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 6,
                color: theme.colorScheme.primary,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Historical Data',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(width: 20),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Forecast',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  double _getMetricValue(WeatherData data, int metricIndex) {
    switch (metricIndex) {
      case 0: return data.temperature;
      case 1: return data.precipitation;
      case 2: return data.humidity;
      default: return 0.0;
    }
  }

  double _getInterval(int metricIndex) {
    switch (metricIndex) {
      case 0: return 10.0; // Temperature: every 10°C
      case 1: return 5.0;  // Precipitation: every 5mm
      case 2: return 20.0; // Humidity: every 20%
      default: return 10.0;
    }
  }

  double _getMinY(int metricIndex) {
    final values = widget.historicalData.map((d) => _getMetricValue(d, metricIndex)).toList();
    values.add(_getMetricValue(widget.forecast, metricIndex));

    final minValue = values.reduce((a, b) => a < b ? a : b);

    switch (metricIndex) {
      case 0: return (minValue - 5).floorToDouble(); // Temperature
      case 1: return 0.0; // Precipitation starts at 0
      case 2: return 0.0; // Humidity starts at 0
      default: return minValue.floorToDouble();
    }
  }

  double _getMaxY(int metricIndex) {
    final values = widget.historicalData.map((d) => _getMetricValue(d, metricIndex)).toList();
    values.add(_getMetricValue(widget.forecast, metricIndex));

    final maxValue = values.reduce((a, b) => a > b ? a : b);

    switch (metricIndex) {
      case 0: return (maxValue + 5).ceilToDouble(); // Temperature
      case 1: return (maxValue + 2).ceilToDouble(); // Precipitation
      case 2: return 100.0; // Humidity max at 100%
      default: return maxValue.ceilToDouble();
    }
  }

  String _formatYAxisLabel(double value, int metricIndex) {
    switch (metricIndex) {
      case 0: return '${value.round()}°'; // Temperature
      case 1: return '${value.round()}mm'; // Precipitation
      case 2: return '${value.round()}%'; // Humidity
      default: return value.round().toString();
    }
  }
}