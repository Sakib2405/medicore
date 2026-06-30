import 'package:flutter/material.dart';
import 'package:medicore/services/symptom_checker_service.dart';

class AiProvider extends ChangeNotifier {
  final SymptomCheckerService _symptomService = SymptomCheckerService();
  String? _analysisResult;
  bool _isLoading = false;

  // Getters
  String? get analysisResult => _analysisResult;
  bool get isLoading => _isLoading;

  Future<void> analyzeSymptoms(
      List<String> symptoms, String otherSymptoms) async {
    _isLoading = true;
    _analysisResult = null;
    notifyListeners();

    try {
      _analysisResult =
          await _symptomService.checkSymptoms(symptoms, otherSymptoms);
    } catch (e) {
      _analysisResult = "Sorry, an error occurred: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
