import 'package:memora/data/datasources/notion_remote_data_source.dart';
import 'package:memora/models/notion_page.dart'; // Added
import 'package:memora/repositories/notion/notion_auth_repository.dart';

class NotionRepository {
  final NotionAuthRepository _notionAuthRepository;
  final NotionRemoteDataSource _remoteDataSource;

  NotionRepository({
    required NotionAuthRepository notionAuthRepository,
    required NotionRemoteDataSource remoteDataSource,
  }) : _notionAuthRepository = notionAuthRepository,
       _remoteDataSource = remoteDataSource;

  Future<String> _getApiToken() async {
    final tokenData = await _notionAuthRepository.getApiKeyWithTimestamp();
    final apiToken = tokenData['value'];

    if (apiToken == null || apiToken.isEmpty) {
      throw Exception('Notion API token is not set.');
    }
    return apiToken;
  }

  Future<List<NotionPage>> searchPages({String? query}) async {
    final apiToken = await _getApiToken();
    final response = await _remoteDataSource.searchPages(
      apiToken,
      query: query,
    );
    return (response['results'] as List)
        .map((json) => NotionPage.fromMap(json))
        .toList();
  }

  Future<Map<String, dynamic>> getPagesFromDB(
    String databaseId,
    String? startCursor,
  ) async {
    final apiToken = await _getApiToken();
    return _remoteDataSource.getPagesFromDB(apiToken, databaseId, startCursor);
  }

  Future<Map<String, dynamic>> getDatabaseInfo(String databaseId) async {
    final apiToken = await _getApiToken();
    return _remoteDataSource.getDatabaseInfo(apiToken, databaseId);
  }

  Future<String> getPageContent(String pageId) async {
    final apiToken = await _getApiToken();
    return _remoteDataSource.getPageContent(apiToken, pageId);
  }

  Future<Map<String, dynamic>> searchDatabases({String? query}) async {
    final apiToken = await _getApiToken();
    return _remoteDataSource.searchDatabases(apiToken, query: query);
  }

  Future<Map<String, dynamic>> getRoadmapTasksFromDB(String databaseId) async {
    final apiToken = await _getApiToken();
    return _remoteDataSource.getRoadmapTasksFromDB(apiToken, databaseId);
  }

  Future<List<Map<String, String>>> getQuizDataFromDB(String databaseId) async {
    final apiToken = await _getApiToken();
    return _remoteDataSource.getQuizDataFromDB(apiToken, databaseId);
  }

  Future<Map<String, dynamic>> fetchPageBlocks(String pageId) async {
    final apiToken = await _getApiToken();
    return _remoteDataSource.fetchPageBlocks(apiToken, pageId);
  }

  Future<bool> validateApiKey(String apiToken) {
    return _remoteDataSource.validateApiKey(apiToken);
  }
}
