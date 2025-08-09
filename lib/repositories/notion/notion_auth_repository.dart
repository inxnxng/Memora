import 'package:memora/services/local_storage_service.dart';

class NotionAuthRepository {
  final LocalStorageService _localStorageService;

  NotionAuthRepository(this._localStorageService);
  String service = 'notion';

  Future<Map<String, String?>> getApiKeyWithTimestamp() {
    return _localStorageService.getApiKeyWithTimestamp(service);
  }

  Future<void> saveApiKeyWithTimestamp(String apiKey) {
    return _localStorageService.saveApiKeyWithTimestamp(service, apiKey);
  }

  Future<void> deleteApiKey() {
    return _localStorageService.deleteApiKey(service);
  }

  Future<void> saveApiKeyValidStatus(bool isValid) {
    return _localStorageService.saveApiKeyValidStatus(service, isValid);
  }

  Future<bool?> getApiKeyValidStatus() {
    return _localStorageService.getApiKeyValidStatus(service);
  }
}
