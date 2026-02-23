import 'package:flutter/foundation.dart';
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
    final hasValue = keyData['value'] != null && keyData['value']!.isNotEmpty;
    final isValid = await _geminiAuthRepository.getApiKeyValidStatus();
    final result = hasValue && (isValid ?? false);
    debugPrint(
      '[GeminiService] checkApiKeyAvailability: hasKey=$hasValue '
      'validStatus=$isValid (raw) => result=$result',
    );
    if (!hasValue) {
      debugPrint('[GeminiService] 키가 없거나 비어 있음');
    } else if (isValid != true) {
      debugPrint('[GeminiService] 유효 상태가 true가 아님 (저장값: $isValid). 설정에서 키를 다시 저장하면 true로 설정됩니다.');
    }
    return result;
  }

  Future<Map<String, String?>> getApiKeyWithTimestamp() {
    return _geminiAuthRepository.getApiKeyWithTimestamp();
  }

  Future<bool> validateAndSaveApiKey(String apiKey) async {
    debugPrint('[GeminiService] validateAndSaveApiKey: API 호출로 키 검사 중...');
    final isValid = await _geminiRepository.validateApiKey(apiKey);
    debugPrint('[GeminiService] validateAndSaveApiKey: 검사 결과 isValid=$isValid');
    if (isValid) {
      await _geminiAuthRepository.saveApiKeyValidStatus(true);
      await _geminiAuthRepository.saveApiKeyWithTimestamp(apiKey);
      debugPrint('[GeminiService] 키 저장 및 valid=true 설정 완료');
    }
    return isValid;
  }

  /// API 사용 중 키 오류가 났을 때 호출. 저장된 유효 상태를 무효로 표시합니다.
  Future<void> markKeyInvalid() async {
    await _geminiAuthRepository.saveApiKeyValidStatus(false);
  }

  Future<void> saveApiKeyWithTimestamp(String apiKey) async {
    await validateAndSaveApiKey(apiKey);
  }

  /// 검증 없이 키만 저장. 유효하지 않은 키를 사용자가 '그래도 저장'할 때 사용.
  Future<void> saveApiKeyWithoutValidation(String apiKey) async {
    await _geminiAuthRepository.saveApiKeyValidStatus(false);
    await _geminiAuthRepository.saveApiKeyWithTimestamp(apiKey);
    debugPrint('[GeminiService] 키 저장 완료 (검증 없음, valid=false)');
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
