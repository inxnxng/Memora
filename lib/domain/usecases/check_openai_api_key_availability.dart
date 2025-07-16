import 'package:memora/domain/repositories/openai_api_key_repository.dart';

class CheckOpenAIApiKeyAvailability {
  final OpenAIApiKeyRepository repository;

  CheckOpenAIApiKeyAvailability(this.repository);

  Future<bool> call() async {
    final keyData = await repository.getApiKeyWithTimestamp();
    return keyData['value'] != null && keyData['value']!.isNotEmpty;
  }
}
