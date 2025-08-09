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
    if (keyData['value'] == null || keyData['value']!.isEmpty) {
      return false;
    }
    final isValid = await _openAIAuthRepository.getApiKeyValidStatus();
    return isValid ?? false;
  }

  Future<Map<String, String?>> getApiKeyWithTimestamp() {
    return _openAIAuthRepository.getApiKeyWithTimestamp();
  }

  Future<bool> validateAndSaveApiKey(String apiKey) async {
    final isValid = await _openAIRepository.validateApiKey(apiKey);
    await _openAIAuthRepository.saveApiKeyValidStatus(isValid);
    if (isValid) {
      await _openAIAuthRepository.saveApiKeyWithTimestamp(apiKey);
    }
    return isValid;
  }

  Future<void> saveApiKeyWithTimestamp(String apiKey) async {
    await validateAndSaveApiKey(apiKey);
  }

  Future<void> deleteApiKey() {
    return _openAIAuthRepository.deleteApiKey();
  }

  // --- Core AI Functionality ---

  Stream<String> generateTrainingContentStream(
    List<Map<String, String>> messages,
  ) {
    return _openAIRepository.generateTrainingContentStream(messages);
  }

  Future<Map<String, dynamic>> createQuizFromText(String text) {
    return _openAIRepository.createQuizFromText(text);
  }

  Future<String> generateTrainingContent(List<Map<String, String>> messages) {
    return _openAIRepository.generateTrainingContent(messages);
  }
}
