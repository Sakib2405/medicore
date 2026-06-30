// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static final _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

  static Future<String> getReply(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
            'No reply';
      } else {
        print('Gemini API error: ${response.statusCode} ${response.body}');
        return 'Error: Gemini API returned ${response.statusCode}';
      }
    } catch (e) {
      print('GeminiService exception: $e');
      return 'Error: Failed to connect to Gemini API.';
    }
  }
}
