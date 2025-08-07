import 'package:memora/services/local_storage_service.dart';

class GeminiAuthRepository {
  final LocalStorageService _localStorageService;

  GeminiAuthRepository(this._localStorageService);
  String service = 'gemini';

  Future<Map<String, String?>> getApiKeyWithTimestamp() {
    return _localStorageService.getApiKeyWithTimestamp(service);
  }

  Future<void> saveApiKeyWithTimestamp(String apiKey) {
    return _localStorageService.saveApiKeyWithTimestamp(service, apiKey);
  }

  Future<void> deleteApiKey() {
    return _localStorageService.deleteApiKey(service);
  }
}
