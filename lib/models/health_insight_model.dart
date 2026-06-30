// lib/models/health_insight_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum InsightSeverity { info, low, medium, high, critical }

class HealthInsightModel {
  final String id;
  final String title; // e.g., "Sleep Pattern Change", "Activity Goal Met"
  final String description; // Detailed insight text
  final InsightSeverity severity; // How important is this insight?
  final String category; // e.g., 'Sleep', 'Activity', 'Vitals', 'Medication'
  final DateTime timestamp; // When the insight was generated
  final String?
      actionableLink; // Optional route name for action (e.g., '/sleep-log')
  final String?
      relatedDataId; // Optional ID of related data (e.g., appointmentId)

  HealthInsightModel({
    required this.id,
    required this.title,
    required this.description,
    this.severity = InsightSeverity.info,
    required this.category,
    required this.timestamp,
    this.actionableLink,
    this.relatedDataId,
  });

  // Factory constructor from Firestore map
  factory HealthInsightModel.fromMap(Map<String, dynamic> map, String id) {
    return HealthInsightModel(
      id: id,
      title: map['title'] ?? 'Insight',
      description: map['description'] ?? 'No details available.',
      severity: _parseSeverity(map['severity'] ?? 'info'),
      category: map['category'] ?? 'General',
      timestamp: (map['timestamp'] as Timestamp? ?? Timestamp.now()).toDate(),
      actionableLink: map['actionableLink'],
      relatedDataId: map['relatedDataId'],
    );
  }

  // Helper to parse severity string to enum
  static InsightSeverity _parseSeverity(String severityStr) {
    return InsightSeverity.values.firstWhere(
        (e) => e.toString().split('.').last == severityStr.toLowerCase(),
        orElse: () => InsightSeverity.info);
  }

  // Convert to map for Firestore (optional, if you save insights)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'severity': severity.toString().split('.').last,
      'category': category,
      'timestamp': Timestamp.fromDate(timestamp),
      'actionableLink': actionableLink,
      'relatedDataId': relatedDataId,
    };
  }
}
