import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiRemoteDataSource {
  Future<String> generateQuizFromText(String text, String apiKey) async {
    final model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
    final prompt =
        'Create a quiz from the following text. The quiz should be in JSON format with questions and answers. Text: $text';
    final content = [Content.text(prompt)];
    final response = await model.generateContent(content);
    return response.text ?? '';
  }
}
