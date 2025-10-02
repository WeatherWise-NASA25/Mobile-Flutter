import 'package:flutter/material.dart';
import '../models/weather_model.dart';

class RiskAssessmentCard extends StatelessWidget {
  final WeatherRiskAssessment riskAssessment;
  final String eventType;

  const RiskAssessmentCard({
    super.key,
    required this.riskAssessment,
    required this.eventType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.assessment,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Risk Assessment',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Overall risk indicator
            _buildOverallRiskIndicator(context),

            const SizedBox(height: 24),

            // Individual risk factors
            _buildRiskFactors(context),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallRiskIndicator(BuildContext context) {
    final theme = Theme.of(context);
    final riskColor = _getRiskColor(riskAssessment.overallRisk);
    final riskLabel = _getRiskLabel(riskAssessment.overallRisk);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: riskColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: riskColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: riskColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getRiskIcon(riskAssessment.overallRisk),
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall Risk Level',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$riskLabel (${(riskAssessment.overallRisk * 100).round()}%)',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: riskColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskFactors(BuildContext context) {
    return Column(
      children: [
        _buildRiskFactor(
          context,
          'Precipitation Risk',
          riskAssessment.precipitationRisk,
          Icons.water_drop,
          'Risk of rain during your event',
        ),
        const SizedBox(height: 12),
        _buildRiskFactor(
          context,
          'Temperature Risk',
          riskAssessment.temperatureRisk,
          Icons.thermostat,
          'Risk of uncomfortable temperatures',
        ),
        const SizedBox(height: 12),
        _buildRiskFactor(
          context,
          'Wind Risk',
          riskAssessment.windRisk,
          Icons.air,
          'Risk of high winds affecting setup',
        ),
        const SizedBox(height: 12),
        _buildRiskFactor(
          context,
          'Visibility Risk',
          riskAssessment.visibilityRisk,
          Icons.visibility,
          'Risk of poor visibility conditions',
        ),
      ],
    );
  }

  Widget _buildRiskFactor(BuildContext context, String title, double risk, IconData icon, String description) {
    final riskColor = _getRiskColor(risk);
    final riskLabel = _getRiskLabel(risk);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: riskColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                riskLabel,
                style: TextStyle(
                  color: riskColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: risk,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(riskColor),
            minHeight: 6,
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

  String _getRiskLabel(double risk) {
    if (risk <= 0.3) return 'Low';
    if (risk <= 0.6) return 'Medium';
    return 'High';
  }

  IconData _getRiskIcon(double risk) {
    if (risk <= 0.3) return Icons.check_circle;
    if (risk <= 0.6) return Icons.warning;
    return Icons.error;
  }
}