import 'package:memora/domain/usecases/openai_usecases.dart';

class OpenAIService {
  final OpenAIUsecases _openAIUsecases;

  OpenAIService(this._openAIUsecases);

  Future<String> generateTrainingContent(String userPrompt) async {
    return await _openAIUsecases.generateTrainingContent(userPrompt);
  }

  Future<Map<String, dynamic>> createQuizFromText(String text) async {
    return await _openAIUsecases.createQuizFromText(text);
  }
}
