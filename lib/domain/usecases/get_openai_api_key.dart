import 'package:memora/domain/repositories/openai_api_key_repository.dart';

class GetOpenAIApiKey {
  final OpenAIApiKeyRepository repository;

  GetOpenAIApiKey(this.repository);

  Future<Map<String, String?>> call() {
    return repository.getApiKeyWithTimestamp();
  }
}
