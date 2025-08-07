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
    return keyData['value'] != null && keyData['value']!.isNotEmpty;
  }

  Future<Map<String, String?>> getApiKeyWithTimestamp() {
    return _geminiAuthRepository.getApiKeyWithTimestamp();
  }

  Future<void> saveApiKeyWithTimestamp(String apiKey) {
    return _geminiAuthRepository.saveApiKeyWithTimestamp(apiKey);
  }

  Future<void> deleteApiKey() {
    return _geminiAuthRepository.deleteApiKey();
  }

  // --- Core AI Functionality ---

  Future<String> generateQuizFromText(String text) {
    return _geminiRepository.generateQuizFromText(text);
  }
}
