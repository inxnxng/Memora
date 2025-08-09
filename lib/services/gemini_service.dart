import 'package:memora/repositories/gemini/gemini_auth_repository.dart';
import 'package:memora/repositories/gemini/gemini_repository.dart';

class GeminiService {
  final GeminiAuthRepository _geminiAuthRepository;
  final GeminiRepository _geminiRepository;

  GeminiService({
    required GeminiAuthRepository geminiAuthRepository,
    required GeminiRepository geminiRepository,
  }) : _geminiAuthRepository = geminiAuthRepository,
       _geminiRepository = geminiRepository;

  // --- Key Management ---

  Future<bool> checkApiKeyAvailability() async {
    final keyData = await _geminiAuthRepository.getApiKeyWithTimestamp();
    if (keyData['value'] == null || keyData['value']!.isEmpty) {
      return false;
    }
    final isValid = await _geminiAuthRepository.getApiKeyValidStatus();
    return isValid ?? false;
  }

  Future<Map<String, String?>> getApiKeyWithTimestamp() {
    return _geminiAuthRepository.getApiKeyWithTimestamp();
  }

  Future<bool> validateAndSaveApiKey(String apiKey) async {
    final isValid = await _geminiRepository.validateApiKey(apiKey);
    await _geminiAuthRepository.saveApiKeyValidStatus(isValid);
    if (isValid) {
      await _geminiAuthRepository.saveApiKeyWithTimestamp(apiKey);
    }
    return isValid;
  }

  Future<void> saveApiKeyWithTimestamp(String apiKey) async {
    await validateAndSaveApiKey(apiKey);
  }

  Future<void> deleteApiKey() {
    return _geminiAuthRepository.deleteApiKey();
  }

  // --- Core AI Functionality ---

  Stream<String> generateQuizFromText(List<Map<String, String>> messages) {
    return _geminiRepository.generateQuizFromText(messages);
  }

  Future<String> createQuizFromText(String text) {
    return _geminiRepository.createQuizFromText(text);
  }
}
