import 'package:memora/domain/repositories/openai_repository.dart';

class CreateQuizFromText {
  final OpenAIRepository repository;

  CreateQuizFromText(this.repository);

  Future<Map<String, dynamic>> call(String text) {
    return repository.createQuizFromText(text);
  }
}
