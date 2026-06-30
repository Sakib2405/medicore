// lib/widgets/patient/health_insight_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:medicore/models/health_insight_model.dart'; // Make sure this path is correct

class HealthInsightCard extends StatelessWidget {
  final HealthInsightModel insight;
  final VoidCallback? onTakeAction; // Callback for the primary action button
  final VoidCallback? onViewDetail; // Callback for tapping the card

  const HealthInsightCard({
    super.key,
    required this.insight,
    this.onTakeAction,
    this.onViewDetail,
  });

  Color get backgroundColor => Colors.transparent;

  // --- Helper Methods to Determine Appearance ---

  Color _getSeverityColor(InsightSeverity severity) {
    switch (severity) {
      case InsightSeverity.critical:
        return Colors.red;
      case InsightSeverity.high:
        return Colors.red.shade700; // Correctly get shade
      case InsightSeverity.medium:
        return Colors.orange;
      case InsightSeverity.low:
        return Colors.green;
      case InsightSeverity.info:
        return Colors.blue; // Using standard blue
    }
  }

  IconData _getSeverityIcon(InsightSeverity severity) {
    switch (severity) {
      case InsightSeverity.critical:
        return Icons.dangerous_outlined;
      case InsightSeverity.high:
        return Icons.warning_amber_outlined;
      case InsightSeverity.medium:
        return Icons.lightbulb_outline;
      case InsightSeverity.low:
        return Icons.info_outline;
      case InsightSeverity.info:
        return Icons.monitor_heart_outlined;
    }
  }

  String _getSeverityText(InsightSeverity severity) {
    return severity.toString().split('.').last.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color color = _getSeverityColor(insight.severity);
    final String severityText = _getSeverityText(insight.severity);
    final IconData icon = _getSeverityIcon(insight.severity);
    final bool hasAction = onTakeAction != null;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onViewDetail ?? onTakeAction, // Tap to view or take action
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header: Icon, Title, and Severity Tag ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          insight.title,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          insight.category,
                          style: theme.textTheme.labelMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  _buildSeverityChip(color, severityText),
                ],
              ),
              const SizedBox(height: 12),

              // --- Description ---
              Text(
                insight.description,
                style: theme.textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // --- Footer: Timestamp and Action Button ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat.yMd().format(insight.timestamp),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey[600]),
                  ),
                  if (hasAction)
                    SizedBox(
                      height: 32, // Smaller button height
                      child: ElevatedButton(
                        onPressed: onTakeAction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          textStyle: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        child: const Text('Take Action'),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeverityChip(Color color, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(35), // 14% opacity
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
