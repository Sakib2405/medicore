// lib/models/symptom_model.dart

/// Represents a single symptom.
class SymptomModel {
  final String id;
  final String name;
  final String description;

  SymptomModel({
    required this.id,
    required this.name,
    required this.description,
  });
}

/// Represents one possible condition found by the analysis.
/// This is a nested model inside SymptomAnalysisResult.
class PossibleCondition {
  final String name;
  final String severity; // e.g., 'mild', 'moderate', 'severe'
  final double probability; // e.g., 0.85 (for 85%)

  PossibleCondition({
    required this.name,
    required this.severity,
    required this.probability,
  });
}

/// This is the main class you were missing.
/// It holds the complete result of a symptom check.
class SymptomAnalysisResult {
  final String id;
  final List<SymptomModel> symptoms; // The symptoms the user entered
  final List<PossibleCondition> possibleConditions;
  final String riskLevel; // e.g., 'low', 'medium', 'high'
  final List<String> emergencySigns;
  final bool shouldSeeDoctor;
  final DateTime analyzedAt;

  SymptomAnalysisResult({
    required this.id,
    required this.symptoms,
    required this.possibleConditions,
    required this.riskLevel,
    required this.emergencySigns,
    required this.shouldSeeDoctor,
    required this.analyzedAt,
  });
}
