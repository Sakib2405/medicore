// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HealthMonitoringService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _aiBaseUrl = 'https://api.openai.com/v1';

  Future<void> recordHealthData(
      String userId, Map<String, dynamic> healthData) async {
    try {
      await _firestore.collection('health_data').add({
        'userId': userId,
        'data': healthData,
        'recordedAt': FieldValue.serverTimestamp(),
        'type': healthData['type'] ?? 'general',
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getHealthData(
      String userId, String type) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('health_data')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: type)
          .orderBy('recordedAt', descending: true)
          .limit(30)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'data': data['data'],
          'recordedAt': data['recordedAt'],
        };
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<String> analyzeHealthTrends(String userId, String healthType) async {
    try {
      final healthData = await getHealthData(userId, healthType);

      if (healthData.isEmpty) {
        return 'No health data available for analysis.';
      }

      final prompt = """
      Analyze this health data for $healthType:
      ${json.encode(healthData)}
      
      Provide:
      1. Trend analysis
      2. Health insights
      3. Recommendations
      4. Risk assessment
      
      Keep it concise and actionable.
      """;

      final response = await http.post(
        Uri.parse('$_aiBaseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer your-openai-api-key',
        },
        body: json.encode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'max_tokens': 500,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('Failed to analyze health trends');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> calculateHealthMetrics(
      Map<String, dynamic> healthData) async {
    try {
      final bmi = _calculateBMI(healthData['weight'], healthData['height']);
      final bmr = _calculateBMR(healthData['weight'], healthData['height'],
          healthData['age'], healthData['gender']);
      final healthScore = _calculateHealthScore(healthData);

      return {
        'bmi': bmi,
        'bmr': bmr,
        'healthScore': healthScore,
        'bmiCategory': _getBMICategory(bmi),
        'recommendations': _generateRecommendations(healthData, bmi),
      };
    } catch (e) {
      rethrow;
    }
  }

  double _calculateBMI(double weight, double height) {
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

        if (systolic > 140 || diastolic > 90)
          score -= 20;
        else if (systolic > 130 || diastolic > 85) score -= 10;
      }
    }

    final bmi = _calculateBMI(healthData['weight'], healthData['height']);
    if (bmi > 30)
      score -= 15;
    else if (bmi > 25)
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
}
