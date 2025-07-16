import 'package:memora/domain/repositories/openai_api_key_repository.dart';

class SaveOpenAIApiKey {
  final OpenAIApiKeyRepository repository;

  SaveOpenAIApiKey(this.repository);

  Future<void> call(String apiKey) {
    return repository.saveApiKeyWithTimestamp(apiKey);
  }
}
