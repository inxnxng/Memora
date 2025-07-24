import 'package:memora/repositories/openai_api_key_repository.dart';
import 'package:memora/repositories/openai_repository.dart';

class OpenAIUsecases {
  final OpenAIApiKeyRepository apiKeyRepository;
  final OpenAIRepository openAIRepository;

  OpenAIUsecases({
    required this.apiKeyRepository,
    required this.openAIRepository,
  });

  Future<bool> checkApiKeyAvailability() async {
    final keyData = await apiKeyRepository.getApiKeyWithTimestamp();
    return keyData['value'] != null && keyData['value']!.isNotEmpty;
  }

  Future<Map<String, dynamic>> createQuizFromText(String text) =>
      openAIRepository.createQuizFromText(text);
  Future<String> generateTrainingContent(String userPrompt) =>
      openAIRepository.generateTrainingContent(userPrompt);
  Future<Map<String, String?>> getApiKeyWithTimestamp() =>
      apiKeyRepository.getApiKeyWithTimestamp();
  Future<void> saveApiKeyWithTimestamp(String apiKey) =>
      apiKeyRepository.saveApiKeyWithTimestamp(apiKey);
}
