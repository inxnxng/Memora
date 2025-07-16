import 'dart:convert';

import 'package:http/http.dart' as http;

class OpenAIRemoteDataSource {
  final String apiKey;
  OpenAIRemoteDataSource({required this.apiKey});
  Future<String> generateTrainingContent(String userPrompt) async {
    if (apiKey.isEmpty) {
      throw Exception('OpenAI API key not found.');
    }
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini', // Or gpt-4o if available and desired
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
    if (apiKey.isEmpty) {
      throw Exception('OpenAI API key not found.');
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
