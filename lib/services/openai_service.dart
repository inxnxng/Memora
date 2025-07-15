import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OpenAIService {
  static const String _apiKeyPrefKey = 'openai_api_key';
  static const String _apiKeyTimestampPrefKey = 'openai_api_key_timestamp';

  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    String? apiKey = prefs.getString(_apiKeyPrefKey);
    return apiKey;
  }

  Future<Map<String, String?>> getApiKeyWithTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString(_apiKeyPrefKey);
    final timestamp = prefs.getString(_apiKeyTimestampPrefKey);
    return {'apiKey': apiKey, 'timestamp': timestamp};
  }

  Future<void> saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPrefKey, apiKey);
    await prefs.setString(
      _apiKeyTimestampPrefKey,
      DateTime.now().toIso8601String(),
    );
  }

  Future<bool> isApiKeyAvailable() async {
    final apiKey = await getApiKey();
    return apiKey != null && apiKey.isNotEmpty;
  }

  Future<String> generateTrainingContent(String userPrompt) async {
    final apiKey = await getApiKey();
    if (apiKey == null) {
      throw Exception(
        'OpenAI API key not found. Please set it in the settings.',
      );
    }

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo', // Or gpt-4o if available and desired
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a helpful and encouraging memory training assistant. Your goal is to guide the user through memory exercises and provide feedback. Keep responses concise and engaging.',
          },
          {'role': 'user', 'content': userPrompt},
        ],
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final body = json.decode(utf8.decode(response.bodyBytes));
      return body['choices'][0]['message']['content'];
    } else if (response.statusCode == 401) {
      throw Exception(
        'OpenAI API key is invalid or unauthorized. Please check your key.',
      );
    } else {
      throw Exception('Failed to generate training content: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> createQuizFromText(String text) async {
    final apiKey = await getApiKey();
    if (apiKey == null) {
      throw Exception(
        'OpenAI API key not found. Please set it in the settings.',
      );
    }

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a helpful assistant that creates quizzes. Provide the output in JSON format.',
          },
          {
            'role': 'user',
            'content':
                '다음 텍스트를 기반으로 객관식 퀴즈를 1개 만들어줘. 질문(question), 4개의 선택지(options, list of strings), 정답 인덱스(answer, 0-3)를 포함하는 JSON 형식으로 반환해줘.\n\n$text',
          },
        ],
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final body = json.decode(utf8.decode(response.bodyBytes));
      final content = body['choices'][0]['message']['content'];
      return json.decode(content);
    } else if (response.statusCode == 401) {
      throw Exception(
        'OpenAI API key is invalid or unauthorized. Please check your key.',
      );
    } else {
      throw Exception('Failed to create quiz: ${response.body}');
    }
  }
}
