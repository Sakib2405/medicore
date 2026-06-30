class AnalysisModel {
  final String id;
  final String patientId;
  final String patientName;
  final String doctorId;
  final DateTime analysisDate;
  final Map<String, dynamic> vitalSigns;
  final Map<String, dynamic> labResults;
  final List<String> conditions;
  final double riskScore;
  final String riskLevel; // 'low', 'medium', 'high', 'critical'
  final List<String> recommendations;
  final List<String> aiInsights;
  final String status; // 'pending', 'completed', 'reviewed'
  final DateTime createdAt;

  AnalysisModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.analysisDate,
    required this.vitalSigns,
    required this.labResults,
    required this.conditions,
    required this.riskScore,
    required this.riskLevel,
    required this.recommendations,
    required this.aiInsights,
    this.status = 'completed',
    required this.createdAt,
  });

  factory AnalysisModel.fromMap(Map<String, dynamic> map) {
    return AnalysisModel(
      id: map['id'] ?? '',
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? '',
      doctorId: map['doctorId'] ?? '',
      analysisDate: DateTime.parse(map['analysisDate']),
      vitalSigns: Map<String, dynamic>.from(map['vitalSigns'] ?? {}),
      labResults: Map<String, dynamic>.from(map['labResults'] ?? {}),
      conditions: List<String>.from(map['conditions'] ?? []),
      riskScore: (map['riskScore'] ?? 0.0).toDouble(),
      riskLevel: map['riskLevel'] ?? 'low',
      recommendations: List<String>.from(map['recommendations'] ?? []),
      aiInsights: List<String>.from(map['aiInsights'] ?? []),
      status: map['status'] ?? 'completed',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'doctorId': doctorId,
      'analysisDate': analysisDate.toIso8601String(),
      'vitalSigns': vitalSigns,
      'labResults': labResults,
      'conditions': conditions,
      'riskScore': riskScore,
      'riskLevel': riskLevel,
      'recommendations': recommendations,
      'aiInsights': aiInsights,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
