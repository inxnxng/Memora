import 'package:memora/domain/repositories/notion_repository.dart';
import 'package:memora/data/datasources/notion_remote_data_source.dart';
import 'package:memora/domain/repositories/notion_auth_repository.dart';

class NotionRepositoryImpl implements NotionRepository {
  final NotionAuthRepository authRepository;

  NotionRepositoryImpl({required this.authRepository});

  Future<String> _getApiToken() async {
    final tokenData = await authRepository.getApiTokenWithTimestamp();
    final apiToken = tokenData['value'];
    if (apiToken == null || apiToken.isEmpty) {
      throw Exception('Notion API token not found.');
    }
    return apiToken;
  }

  @override
  Future<List<dynamic>> getPagesFromDB(String databaseId) async {
    final apiToken = await _getApiToken();
    final remoteDataSource = NotionRemoteDataSource(apiToken: apiToken);
    return remoteDataSource.getPagesFromDB(databaseId);
  }

  @override
  Future<Map<String, dynamic>> getDatabaseInfo(String databaseId) async {
    final apiToken = await _getApiToken();
    final remoteDataSource = NotionRemoteDataSource(apiToken: apiToken);
    return remoteDataSource.getDatabaseInfo(databaseId);
  }

  @override
  Future<String> getPageContent(String pageId) async {
    final apiToken = await _getApiToken();
    final remoteDataSource = NotionRemoteDataSource(apiToken: apiToken);
    return remoteDataSource.getPageContent(pageId);
  }

  @override
  Future<List<dynamic>> searchDatabases({String? query}) async {
    final apiToken = await _getApiToken();
    final remoteDataSource = NotionRemoteDataSource(apiToken: apiToken);
    return remoteDataSource.searchDatabases(query: query);
  }

  @override
  Future<List<dynamic>> getRoadmapTasksFromDB(String databaseId) async {
    final apiToken = await _getApiToken();
    final remoteDataSource = NotionRemoteDataSource(apiToken: apiToken);
    return remoteDataSource.getRoadmapTasksFromDB(databaseId);
  }

  @override
  Future<List<Map<String, String>>> getQuizDataFromDB(String databaseId) async {
    final apiToken = await _getApiToken();
    final remoteDataSource = NotionRemoteDataSource(apiToken: apiToken);
    return remoteDataSource.getQuizDataFromDB(databaseId);
  }
}
