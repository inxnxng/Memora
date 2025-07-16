import 'package:memora/domain/repositories/openai_repository.dart';

class GenerateTrainingContent {
  final OpenAIRepository repository;

  GenerateTrainingContent(this.repository);

  Future<String> call(String userPrompt) {
    return repository.generateTrainingContent(userPrompt);
  }
}
