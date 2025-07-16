import 'package:memora/domain/repositories/openai_api_key_repository.dart';
import 'package:memora/services/local_storage_service.dart';

class OpenAIApiKeyRepositoryImpl implements OpenAIApiKeyRepository {
  final LocalStorageService _localStorageService;

  OpenAIApiKeyRepositoryImpl(this._localStorageService);

  @override
  Future<Map<String, String?>> getApiKeyWithTimestamp() {
    return _localStorageService.getApiKeyWithTimestamp();
  }

  @override
  Future<void> saveApiKeyWithTimestamp(String apiKey) {
    return _localStorageService.saveApiKeyWithTimestamp(apiKey);
  }
}
