import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:memora/constants/openai_constants.dart';

class OpenApiException implements Exception {
  final String message;
  final int? statusCode;
  OpenApiException(this.message, {this.statusCode});

  @override
  String toString() {
    return 'OpenApiException: $message (Status code: $statusCode)';
  }
}

class OpenAIRemoteDataSource {
  OpenAIRemoteDataSource();

  Stream<String> generateTrainingContentStream(
    String userPrompt,
    String apiKey,
  ) {
    if (apiKey.isEmpty) {
      return Stream.error(OpenApiException('OpenAI API key not found.'));
    }

    final client = http.Client();
    final request = http.Request(
      'POST',
      Uri.parse('https://api.openai.com/v1/chat/completions'),
    );

    request.headers.addAll({
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    });

    request.body = jsonEncode({
      'model': OpenAIConstants.gpt4oMini,
      'messages': [
        {
          'role': 'system',
          'content': OpenAIConstants.memoryTrainingAssistantPrompt,
        },
        {'role': 'user', 'content': userPrompt},
      ],
      'temperature': 0.7,
      'stream': true,
    });

    return client
        .send(request)
        .asStream()
        .asyncExpand((response) {
          if (response.statusCode == 200) {
            return response.stream
                .transform(utf8.decoder)
                .transform(const LineSplitter())
                .where((line) => line.startsWith('data: בו'))
                .map((line) => line.substring(6))
                .where((data) => data.trim() != '[DONE]')
                .map((data) {
                  final json = jsonDecode(data);
                  return json['choices'][0]['delta']['content'] as String? ??
                      '';
                });
          } else {
            return response.stream.bytesToString().asStream().asyncMap((body) {
              if (response.statusCode == 401) {
                throw OpenApiException(
                  'OpenAI API key is invalid or unauthorized. Please check your key.',
                  statusCode: 401,
                );
              } else {
                throw OpenApiException(
                  'Failed to generate training content: ${response.statusCode} $body',
                  statusCode: response.statusCode,
                );
              }
            });
          }
        })
        .handleError((error) {
          client.close();
          throw error;
        })
        .doOnDone(() {
          client.close();
        });
  }

  Future<String> generateTrainingContent(
    String userPrompt,
    String apiKey,
  ) async {
    if (apiKey.isEmpty) {
      throw OpenApiException('OpenAI API key not found.');
    }
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': OpenAIConstants.gpt4oMini,
        'messages': [
          {
            'role': 'system',
            'content': OpenAIConstants.memoryTrainingAssistantPrompt,
          },
          {'role': 'user', 'content': userPrompt},
        ],
        'temperature': 0.7,
      }),
    );
    if (response.statusCode == 200) {
      final body = json.decode(utf8.decode(response.bodyBytes));
      return body['choices'][0]['message']['content'];
    } else {
      throw OpenApiException(
        'Failed to generate training content: ${response.body}',
        statusCode: response.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> createQuizFromText(
    String text,
    String apiKey,
  ) async {
    if (apiKey.isEmpty) {
      throw OpenApiException('OpenAI API key not found.');
    }
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': OpenAIConstants.gpt35Turbo,
        'messages': [
          {'role': 'system', 'content': OpenAIConstants.quizCreatorPrompt},
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
      try {
        return json.decode(content);
      } catch (e) {
        throw OpenApiException(
          'Failed to parse quiz JSON from OpenAI response: $content',
        );
      }
    } else {
      throw OpenApiException(
        'Failed to create quiz: ${response.body}',
        statusCode: response.statusCode,
      );
    }
  }
}

extension StreamDo<T> on Stream<T> {
  Stream<T> doOnDone(void Function() onDone) {
    return transform(
      StreamTransformer.fromHandlers(
        handleDone: (sink) {
          onDone();
          sink.close();
        },
      ),
    );
  }
}
