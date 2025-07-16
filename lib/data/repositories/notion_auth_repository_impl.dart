import 'package:memora/domain/repositories/notion_auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotionAuthRepositoryImpl implements NotionAuthRepository {
  static const String _apiTokenKey = 'notion_api_token';
  static const String _apiTokenTimestampKey = 'notion_api_token_timestamp';

  @override
  Future<Map<String, String?>> getApiTokenWithTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final apiToken = prefs.getString(_apiTokenKey);
    final timestamp = prefs.getString(_apiTokenTimestampKey);
    return {'value': apiToken, 'timestamp': timestamp};
  }

  @override
  Future<void> saveApiToken(String apiToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiTokenKey, apiToken);
    await prefs.setString(
      _apiTokenTimestampKey,
      DateTime.now().toIso8601String(),
    );
  }

  @override
  Future<void> clearApiToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiTokenKey);
    await prefs.remove(_apiTokenTimestampKey);
  }
}
