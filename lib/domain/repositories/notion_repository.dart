abstract class NotionRepository {
  Future<List<dynamic>> getPagesFromDB(String databaseId);
  Future<Map<String, dynamic>> getDatabaseInfo(String databaseId);
  Future<String> getPageContent(String pageId);
  Future<List<dynamic>> searchDatabases({String? query});
  Future<List<dynamic>> getRoadmapTasksFromDB(String databaseId);
  Future<List<Map<String, String>>> getQuizDataFromDB(String databaseId);
}
