import 'package:medicore/services/ai_service.dart';

class SymptomCheckerService {
  final AiService _aiService = AiService();

  Future<String> checkSymptoms(
      List<String> symptoms, String otherSymptoms) async {
    // This service acts as a specific wrapper around the AiService
    return _aiService.analyzeSymptoms(symptoms, otherSymptoms);
  }
}
