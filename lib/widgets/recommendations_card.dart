import 'package:flutter/material.dart';
import '../models/weather_model.dart';

class RecommendationsCard extends StatelessWidget {
  final List<String> recommendations;
  final String riskLevel;

  const RecommendationsCard({
    super.key,
    required this.recommendations,
    required this.riskLevel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final riskColor = _getRiskColor(riskLevel);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recommendations',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: riskColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    riskLevel,
                    style: TextStyle(
                      color: riskColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (recommendations.isEmpty)
              _buildEmptyState(context)
            else
              _buildRecommendationsList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 32,
            ),
            SizedBox(height: 8),
            Text(
              'Perfect conditions!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'No specific recommendations needed for your event.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsList(BuildContext context) {
    return Column(
      children: recommendations.asMap().entries.map((entry) {
        final index = entry.key;
        final recommendation = entry.value;

        return Padding(
          padding: EdgeInsets.only(bottom: index < recommendations.length - 1 ? 12 : 0),
          child: _buildRecommendationItem(context, recommendation, index),
        );
      }).toList(),
    );
  }

  Widget _buildRecommendationItem(BuildContext context, String recommendation, int index) {
    final theme = Theme.of(context);

    // Extract emoji and text
    final parts = recommendation.split(' ');
    String emoji = '';
    String text = recommendation;

    if (parts.isNotEmpty && _isEmoji(parts[0])) {
      emoji = parts[0];
      text = parts.skip(1).join(' ');
    }

    final priority = _getRecommendationPriority(recommendation);
    final priorityColor = _getPriorityColor(priority);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: priorityColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: priorityColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Priority indicator
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 12),
            decoration: BoxDecoration(
              color: priorityColor,
              shape: BoxShape.circle,
            ),
          ),

          // Emoji (if present)
          if (emoji.isNotEmpty) ...[
            Text(
              emoji,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 12),
          ],

          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),

                // Priority badge
                if (priority != 'normal') ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: priorityColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      priority.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isEmoji(String text) {
    // Simple emoji detection
    final emojiPattern = RegExp(r'[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]', unicode: true);
    return emojiPattern.hasMatch(text);
  }

  String _getRecommendationPriority(String recommendation) {
    final upperCase = recommendation.toUpperCase();

    if (upperCase.contains('HIGH') ||
        upperCase.contains('STRONG') ||
        upperCase.contains('EMERGENCY') ||
        upperCase.contains('CRITICAL')) {
      return 'high';
    } else if (upperCase.contains('MODERATE') ||
        upperCase.contains('CONSIDER') ||
        upperCase.contains('RECOMMENDED')) {
      return 'medium';
    }

    return 'normal';
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
      default:
        return Colors.green;
    }
  }
}