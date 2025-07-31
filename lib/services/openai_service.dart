import 'package:memora/repositories/openai/openai_auth_repository.dart';
import 'package:memora/repositories/openai/openai_repository.dart';

class OpenAIService {
  final OpenAIAuthRepository _openAIAuthRepository;
  final OpenAIRepository _openAIRepository;

  OpenAIService({
    required OpenAIAuthRepository openAIAuthRepository,
    required OpenAIRepository openAIRepository,
  }) : _openAIAuthRepository = openAIAuthRepository,
       _openAIRepository = openAIRepository;

  // --- Key Management ---

  Future<bool> checkApiKeyAvailability() async {
    final keyData = await _openAIAuthRepository.getApiKeyWithTimestamp();
    return keyData['value'] != null && keyData['value']!.isNotEmpty;
  }

  Future<Map<String, String?>> getApiKeyWithTimestamp() {
    return _openAIAuthRepository.getApiKeyWithTimestamp();
  }

  Future<void> saveApiKeyWithTimestamp(String apiKey) {
    return _openAIAuthRepository.saveApiKeyWithTimestamp(apiKey);
  }

  Future<void> deleteApiKey() {
    return _openAIAuthRepository.deleteApiKey();
  }

  // --- Core AI Functionality ---

  Stream<String> generateTrainingContentStream(String userPrompt) {
    return _openAIRepository.generateTrainingContentStream(userPrompt);
  }

  Future<Map<String, dynamic>> createQuizFromText(String text) {
    return _openAIRepository.createQuizFromText(text);
  }

  Future<String> generateTrainingContent(String userPrompt) {
    return _openAIRepository.generateTrainingContent(userPrompt);
  }
}
