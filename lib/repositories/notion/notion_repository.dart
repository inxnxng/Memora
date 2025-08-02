import 'package:memora/data/datasources/notion_remote_data_source.dart';
import 'package:memora/repositories/notion/notion_auth_repository.dart';

class NotionRepository {
  final NotionAuthRepository notionAuthRepository;

  NotionRepository({required this.notionAuthRepository});

  Future<String> _getApiToken() async {
    final tokenData = await notionAuthRepository.getApiKeyWithTimestamp();
    final apiToken = tokenData['value'];
    if (apiToken == null || apiToken.isEmpty) {
      throw Exception('Notion API token not found.');
    }
    return apiToken;
  }

  Future<Map<String, dynamic>> getPagesFromDB(
    String databaseId,
    String? startCursor,
  ) async {
    final apiToken = await _getApiToken();
    final remoteDataSource = NotionRemoteDataSource(apiToken: apiToken);
    return remoteDataSource.getPagesFromDB(
      databaseId,
      startCursor,
    );
  }

  Future<Map<String, dynamic>> getDatabaseInfo(String databaseId) async {
    final apiToken = await _getApiToken();
    final remoteDataSource = NotionRemoteDataSource(apiToken: apiToken);
    return remoteDataSource.getDatabaseInfo(databaseId);
  }

  Future<String> getPageContent(String pageId) async {
    final apiToken = await _getApiToken();
    final remoteDataSource = NotionRemoteDataSource(apiToken: apiToken);
    return remoteDataSource.getPageContent(pageId);
  }

  Future<List<dynamic>> searchDatabases({String? query}) async {
    final apiToken = await _getApiToken();
    final remoteDataSource = NotionRemoteDataSource(apiToken: apiToken);
    return remoteDataSource.searchDatabases(query: query);
  }

  Future<List<dynamic>> getRoadmapTasksFromDB(String databaseId) async {
    final apiToken = await _getApiToken();
    final remoteDataSource = NotionRemoteDataSource(apiToken: apiToken);
    return remoteDataSource.getRoadmapTasksFromDB(databaseId);
  }

  Future<List<Map<String, String>>> getQuizDataFromDB(String databaseId) async {
    final apiToken = await _getApiToken();
    final remoteDataSource = NotionRemoteDataSource(apiToken: apiToken);
    return remoteDataSource.getQuizDataFromDB(databaseId);
  }

  Future<List<dynamic>> fetchPageBlocks(String pageId) async {
    final apiToken = await _getApiToken();
    final remoteDataSource = NotionRemoteDataSource(apiToken: apiToken);
    return remoteDataSource.fetchPageBlocks(pageId);
  }
}
