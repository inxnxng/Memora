import 'package:memora/services/local_storage_service.dart';

class OpenAIApiKeyRepository {
  final LocalStorageService _localStorageService;

  OpenAIApiKeyRepository(this._localStorageService);

  Future<Map<String, String?>> getApiKeyWithTimestamp() {
    return _localStorageService.getApiKeyWithTimestamp();
  }

  Future<void> saveApiKeyWithTimestamp(String apiKey) {
    return _localStorageService.saveApiKeyWithTimestamp(apiKey);
  }
}
