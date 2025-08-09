import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:memora/constants/gemini_constants.dart';

class GeminiRemoteDataSource {
  Stream<String> generateQuizFromText(
    List<Map<String, String>> messages,
    String apiKey,
  ) {
    final systemInstruction = messages.firstWhere(
      (m) => m['role'] == 'system',
      orElse: () => {'content': ''},
    )['content']!;

    final history = messages
        .where((m) => m['role'] != 'system')
        .map(
          (m) => Content(m['role'] == 'user' ? 'user' : 'model', [
            TextPart(m['content']!),
          ]),
        )
        .toList();

    final model = GenerativeModel(
      model: GeminiConstants.geminiFlash,
      apiKey: apiKey,
      systemInstruction: Content.system(systemInstruction),
    );

    final chat = model.startChat(
      history: history.sublist(0, history.length - 1),
    );
    final lastMessage = history.last.parts.first as TextPart;

    return chat
        .sendMessageStream(Content.text(lastMessage.text))
        .map((response) => response.text ?? '');
  }

  Future<String> createQuizFromText(String text, String apiKey) async {
    final model = GenerativeModel(
      model: GeminiConstants.geminiFlash,
      apiKey: apiKey,
    );
    final prompt =
        'Create a quiz from the following text. The quiz should be in JSON format with questions and answers. Text: $text';
    final content = [Content.text(prompt)];
    final response = await model.generateContent(content);
    return response.text ?? '';
  }

  Future<bool> validateApiKey(String apiKey) async {
    try {
      final model = GenerativeModel(
        model: GeminiConstants.geminiFlash,
        apiKey: apiKey,
      );
      await model.generateContent([Content.text('hello')]);
      return true;
    } catch (e) {
      return false;
    }
  }
}
