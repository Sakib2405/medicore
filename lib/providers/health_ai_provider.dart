// ignore_for_file: curly_braces_in_flow_control_structures, duplicate_ignore

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicore/models/health_insight_model.dart';

class HealthAIProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Map<String, dynamic> _healthData = {};
  List<Map<String, dynamic>> _healthHistory = [];
  bool _isLoading = false;

  Map<String, dynamic> get healthData => _healthData;
  List<Map<String, dynamic>> get healthHistory => _healthHistory;
  bool get isLoading => _isLoading;

  Future<void> recordHealthData(
      String userId, Map<String, dynamic> data) async {
    try {
      _setLoading(true);
      await _firestore.collection('health_data').add({
        'userId': userId,
        'data': data,
        'recordedAt': FieldValue.serverTimestamp(),
        'type': data['type'] ?? 'general',
      });

      // Update local data
      _healthData.addAll(data);
      await fetchHealthHistory(userId);
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchHealthHistory(String userId) async {
    try {
      _setLoading(true);
      final snapshot = await _firestore
          .collection('health_data')
          .where('userId', isEqualTo: userId)
          .orderBy('recordedAt', descending: true)
          .limit(30)
          .get();

      _healthHistory = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'data': data['data'],
          'recordedAt': data['recordedAt'],
          'type': data['type'],
        };
      }).toList();
      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> calculateHealthMetrics(
      Map<String, dynamic> healthData) async {
    try {
      _setLoading(true);

      final bmi = _calculateBMI(healthData['weight'], healthData['height']);
      final bmr = _calculateBMR(healthData['weight'], healthData['height'],
          healthData['age'], healthData['gender']);
      final healthScore = _calculateHealthScore(healthData);

      final metrics = {
        'bmi': bmi,
        'bmr': bmr,
        'healthScore': healthScore,
        'bmiCategory': _getBMICategory(bmi),
        'recommendations': _generateRecommendations(healthData, bmi),
      };

      _healthData.addAll(metrics);
      notifyListeners();

      return metrics;
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  double _calculateBMI(double weight, double height) {
    // Assuming height is in cm
    return weight / ((height / 100) * (height / 100));
  }

  double _calculateBMR(double weight, double height, int age, String gender) {
    if (gender.toLowerCase() == 'male') {
      return 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
    } else {
      return 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
    }
  }

  double _calculateHealthScore(Map<String, dynamic> healthData) {
    double score = 100.0;

    if (healthData['bloodPressure'] != null) {
      final bp = healthData['bloodPressure'] as String;
      if (bp.contains('/')) {
        final values = bp.split('/');
        final systolic = int.tryParse(values[0]) ?? 120;
        final diastolic = int.tryParse(values[1]) ?? 80;

        if (systolic > 140 || diastolic > 90) {
          score -= 20;
          // ignore: curly_braces_in_flow_control_structures
        } else if (systolic > 130 || diastolic > 85) score -= 10;
      }
    }

    final bmi = _calculateBMI(healthData['weight'], healthData['height']);
    if (bmi > 30) {
      score -= 15;
    } else if (bmi > 25)
      score -= 10;
    else if (bmi < 18.5) score -= 5;

    return score.clamp(0, 100);
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  List<String> _generateRecommendations(
      Map<String, dynamic> healthData, double bmi) {
    final recommendations = <String>[];

    if (bmi > 25) {
      recommendations
          .add('Consider incorporating regular exercise and balanced diet');
    } else if (bmi < 18.5) {
      recommendations
          .add('Focus on nutrient-dense foods and consult a nutritionist');
    }

    if (healthData['bloodPressure'] != null) {
      recommendations.add(
          'Monitor blood pressure regularly and maintain healthy lifestyle');
    }

    recommendations.add('Stay hydrated and get adequate sleep');
    recommendations.add('Schedule regular health check-ups');

    return recommendations;
  }

  void clearHealthData() {
    _healthData.clear();
    _healthHistory.clear();
    notifyListeners();
  }

  Stream<List<HealthInsightModel>> insightsStream(String userId) {
    return _firestore
        .collection('health_insights')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => HealthInsightModel.fromMap(d.data(), d.id))
            .toList());
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
