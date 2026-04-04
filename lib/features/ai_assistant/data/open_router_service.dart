import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class OpenRouterService {
  static final String _apiKey = dotenv.env['OPENROUTER_API_KEY'] ?? '';
  static const String _baseUrl = 'https://openrouter.ai/api/v1';

  static const String defaultModel = 'google/gemini-2.0-flash-001';

  Future<String> generateResponse(String prompt, {String? model}) async {
    if (_apiKey.isEmpty || _apiKey == 'your_openrouter_api_key_here') {
      return "Error: OpenRouter API Key is missing. Please add it to your .env file.";
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer':
              'https://careeriq.app',
          'X-Title': 'CareerIQ App',
        },
        body: jsonEncode({
          'model': model ?? defaultModel,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ??
            "No response from AI.";
      } else {
        final error = jsonDecode(response.body);
        return "OpenRouter Error (${response.statusCode}): ${error['error']?['message'] ?? 'Unknown error'}";
      }
    } catch (e) {
      debugPrint("OpenRouter Exception: $e");
      return "Network Error: Could not reach OpenRouter. Please check your connection.";
    }
  }

  Future<String> sendChatMessage(
    List<Map<String, String>> messages, {
    String? model,
  }) async {
    if (_apiKey.isEmpty || _apiKey == 'your_openrouter_api_key_here') {
      return "Error: OpenRouter API Key is missing.";
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://careeriq.app',
          'X-Title': 'CareerIQ App',
        },
        body: jsonEncode({
          'model': model ?? defaultModel,
          'messages': messages,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ?? "";
      } else {
        return "Chat Error (${response.statusCode})";
      }
    } catch (e) {
      return "Connection Error";
    }
  }
}
