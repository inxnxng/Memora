import 'package:flutter/foundation.dart';
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
    final hasValue = keyData['value'] != null && keyData['value']!.isNotEmpty;
    final isValid = await _openAIAuthRepository.getApiKeyValidStatus();
    final result = hasValue && (isValid ?? false);
    debugPrint(
      '[OpenAIService] checkApiKeyAvailability: hasKey=$hasValue '
      'validStatus=$isValid (raw) => result=$result',
    );
    return result;
  }

  Future<Map<String, String?>> getApiKeyWithTimestamp() {
    return _openAIAuthRepository.getApiKeyWithTimestamp();
  }

  Future<bool> validateAndSaveApiKey(String apiKey) async {
    final isValid = await _openAIRepository.validateApiKey(apiKey);
    if (isValid) {
      await _openAIAuthRepository.saveApiKeyValidStatus(true);
      await _openAIAuthRepository.saveApiKeyWithTimestamp(apiKey);
    }
    return isValid;
  }

  /// API 사용 중 키 오류가 났을 때 호출. 저장된 유효 상태를 무효로 표시합니다.
  Future<void> markKeyInvalid() async {
    await _openAIAuthRepository.saveApiKeyValidStatus(false);
  }

  Future<void> saveApiKeyWithTimestamp(String apiKey) async {
    await validateAndSaveApiKey(apiKey);
  }

  /// 검증 없이 키만 저장. 유효하지 않은 키를 사용자가 '그래도 저장'할 때 사용.
  Future<void> saveApiKeyWithoutValidation(String apiKey) async {
    await _openAIAuthRepository.saveApiKeyValidStatus(false);
    await _openAIAuthRepository.saveApiKeyWithTimestamp(apiKey);
    debugPrint('[OpenAIService] 키 저장 완료 (검증 없음, valid=false)');
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
