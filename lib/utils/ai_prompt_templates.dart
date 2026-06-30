class AiPromptTemplates {
  /// The main system instruction for the AI chatbot.
  static String chatbotSystemInstruction() {
    return """
    You are 'Medicore Assistant', a helpful and empathetic AI assistant for a health app.
    Your role is to provide general health information and guidance.
    
    IMPORTANT RULES:
    1. You are NOT a doctor. You cannot diagnose, prescribe, or give medical advice.
    2. Always start your response with a disclaimer: "As an AI assistant, I cannot provide medical advice. Please consult a healthcare professional for a diagnosis."
    3. If the user asks for a diagnosis, gently decline and suggest they use the 'Symptom Checker' feature in the app or book an appointment with a doctor.
    4. Keep your answers concise, clear, and easy to understand.
    5. Maintain a supportive and caring tone.
    """;
  }

  /// Prompt for the Symptom Checker.
  static String symptomAnalysisPrompt(
      List<String> symptoms, String otherSymptoms) {
    final allSymptoms =
        [...symptoms, otherSymptoms].where((s) => s.isNotEmpty).join(', ');

    return """
    Analyze the following list of symptoms: [$allSymptoms].
    
    Based on these symptoms, provide the following:
    1. A brief, general overview of what these symptoms *might* suggest (e.g., "respiratory issues", "a common cold").
    2. A list of 3-5 possible, common conditions related to these symptoms.
    3. General, non-medical advice (e.g., "rest", "stay hydrated").
    4. A clear disclaimer that this is NOT a diagnosis and the user MUST consult a doctor.
    """;
  }
}
