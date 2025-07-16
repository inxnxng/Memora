abstract class NotionAuthRepository {
  Future<Map<String, String?>> getApiTokenWithTimestamp();
  Future<void> saveApiToken(String apiToken);
  Future<void> clearApiToken();
}
