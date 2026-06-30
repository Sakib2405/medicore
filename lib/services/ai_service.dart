// ignore_for_file: unused_local_variable, unused_field

import 'package:medicore/services/gemini_service.dart';
import 'package:medicore/utils/ai_prompt_templates.dart';

class AiService {
  final GeminiService _geminiService = GeminiService();

  Future<String> analyzeSymptoms(
      List<String> symptoms, String otherSymptoms) async {
    final prompt =
        AiPromptTemplates.symptomAnalysisPrompt(symptoms, otherSymptoms);

    return GeminiService.getReply(prompt);
  }

  Future<String> getAnalyticsInsight() async {
    // const prompt = "Analyze user data and give one insight for an admin dashboard.";

    // --- Mock Response ---
    await Future.delayed(const Duration(seconds: 1));
    return "Peak appointment bookings are on Mondays at 10:00 AM.";
  }
}
