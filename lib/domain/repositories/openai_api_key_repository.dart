abstract class OpenAIApiKeyRepository {
  Future<Map<String, String?>> getApiKeyWithTimestamp();
  Future<void> saveApiKeyWithTimestamp(String apiKey);
}
