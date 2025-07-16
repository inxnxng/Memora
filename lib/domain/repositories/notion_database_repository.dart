abstract class NotionDatabaseRepository {
  Future<Map<String, String?>> getDatabaseIdWithTimestamp();
  Future<void> saveDatabaseId(String databaseId);
  Future<Map<String, String?>> getDatabaseTitleWithTimestamp();
  Future<void> saveDatabaseTitle(String databaseTitle);
  Future<Map<String, String?>> getDatabaseWithTimestamp();
  Future<void> saveDatabase(String database);
  Future<void> clearDatabaseInfo();
  Future<Map<String, String?>> getNotionInfo();
}
