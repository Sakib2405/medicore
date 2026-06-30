import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:medicore/config/env.dart';

class GeminiProxyClient {
  /// Sends a simple text input to the configured proxy and returns the generated text.
  static Future<String> generateTextViaProxy(
    String input, {
    String model = 'gemini-1.5-flash',
    double temperature = 0.7,
    int maxOutputTokens = 512,
  }) async {
    final url = Env.env.geminiProxyUrl;
    if (url.isEmpty) {
      throw Exception('GEMINI_PROXY_URL is not configured in Env.');
    }

    final uri = Uri.parse(url);
    final body = jsonEncode({
      'input': input,
      'model': model,
      'temperature': temperature,
      'maxOutputTokens': maxOutputTokens,
    });

    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      // Parse the generateContent response
      final candidates = data['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'] as Map?;
        if (content != null) {
          final parts = content['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final text = parts[0]['text'] as String?;
            if (text != null) return text;
          }
        }
      }
      throw Exception('Invalid response format from proxy.');
    }

    // Try to surface any JSON error message
    String msg = resp.body;
    try {
      final parsed = jsonDecode(resp.body);
      if (parsed is Map && parsed['error'] != null) {
        final error = parsed['error'];
        if (error is Map && error['message'] != null) {
          msg = error['message'];
        } else if (error is String) {
          msg = error;
        }
      }
    } catch (_) {}
    throw Exception('Proxy call failed (${resp.statusCode}): $msg');
  }
}
