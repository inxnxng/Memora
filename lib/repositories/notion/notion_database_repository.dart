import 'package:shared_preferences/shared_preferences.dart';

class NotionDatabaseRepository {
  static const String _databaseIdKey = 'notion_database_id';
  static const String _databaseIdTimestampKey = 'notion_database_id_timestamp';
  static const String _databaseTitleKey = 'notion_database_title';
  static const String _databaseTitleTimestampKey =
      'notion_database_title_timestamp';
  static const String _databaseKey = 'notion_database';
  static const String _databaseTimestampKey = 'notion_database_timestamp';

  Future<Map<String, String?>> getDatabaseIdWithTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final databaseId = prefs.getString(_databaseIdKey);
    final timestamp = prefs.getString(_databaseIdTimestampKey);
    return {'value': databaseId, 'timestamp': timestamp};
  }

  Future<void> saveDatabaseId(String databaseId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_databaseIdKey, databaseId);
    await prefs.setString(
      _databaseIdTimestampKey,
      DateTime.now().toIso8601String(),
    );
  }

  Future<Map<String, String?>> getDatabaseTitleWithTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final databaseTitle = prefs.getString(_databaseTitleKey);
    final timestamp = prefs.getString(_databaseTitleTimestampKey);
    return {'value': databaseTitle, 'timestamp': timestamp};
  }

  Future<void> saveDatabaseTitle(String databaseTitle) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_databaseTitleKey, databaseTitle);
    await prefs.setString(
      _databaseTitleTimestampKey,
      DateTime.now().toIso8601String(),
    );
  }

  Future<Map<String, String?>> getDatabaseWithTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final database = prefs.getString(_databaseKey);
    final timestamp = prefs.getString(_databaseTimestampKey);
    return {'value': database, 'timestamp': timestamp};
  }

  Future<void> saveDatabase(String database) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_databaseKey, database);
    await prefs.setString(
      _databaseTimestampKey,
      DateTime.now().toIso8601String(),
    );
  }

  Future<void> clearDatabaseInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_databaseIdKey);
    await prefs.remove(_databaseIdTimestampKey);
    await prefs.remove(_databaseTitleKey);
    await prefs.remove(_databaseTitleTimestampKey);
    await prefs.remove(_databaseKey);
    await prefs.remove(_databaseTimestampKey);
  }

  Future<Map<String, String?>> getNotionInfo() async {
    final prefs = await SharedPreferences.getInstance();
    String? databaseId = prefs.getString(_databaseIdKey);
    String? databaseTitle = prefs.getString(_databaseTitleKey);
    String? database = prefs.getString(_databaseKey);

    return {
      'databaseId': databaseId,
      'databaseTitle': databaseTitle,
      'database': database,
    };
  }

  Future<void> saveDatabaseInfo(String databaseId, String databaseTitle) async {
    await saveDatabaseId(databaseId);
    await saveDatabaseTitle(databaseTitle);
  }

  Future<Map<String, String?>> getDatabaseInfo() async {
    final notionInfo = await getNotionInfo();
    return {
      'id': notionInfo['databaseId'],
      'title': notionInfo['databaseTitle'],
    };
  }
}
