import 'package:memora/domain/usecases/create_quiz_from_text.dart';
import 'package:memora/domain/usecases/generate_training_content.dart';

class OpenAIService {
  final GenerateTrainingContent _generateTrainingContent;
  final CreateQuizFromText _createQuizFromText;

  OpenAIService(this._generateTrainingContent, this._createQuizFromText);

  Future<String> generateTrainingContent(String userPrompt) async {
    return await _generateTrainingContent.call(userPrompt);
  }

  Future<Map<String, dynamic>> createQuizFromText(String text) async {
    return await _createQuizFromText.call(text);
  }
}
