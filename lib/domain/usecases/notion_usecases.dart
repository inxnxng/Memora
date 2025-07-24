import 'package:memora/repositories/notion_auth_repository.dart';
import 'package:memora/repositories/notion_database_repository.dart';
import 'package:memora/repositories/notion_repository.dart';
import 'package:memora/services/notion_to_markdown_converter.dart';

class NotionUsecases {
  final NotionAuthRepository notionAuthRepository;
  final NotionDatabaseRepository notionDatabaseRepository;
  final NotionRepository notionRepository;
  final NotionToMarkdownConverter notionToMarkdownConverter;

  NotionUsecases({
    required this.notionAuthRepository,
    required this.notionDatabaseRepository,
    required this.notionRepository,
  }) : notionToMarkdownConverter = NotionToMarkdownConverter();

  Future<void> clearApiToken() => notionAuthRepository.clearApiToken();
  Future<void> clearDatabaseInfo() =>
      notionDatabaseRepository.clearDatabaseInfo();
  Future<Map<String, dynamic>> getDatabaseInfo(String databaseId) =>
      notionRepository.getDatabaseInfo(databaseId);
  Future<Map<String, String?>> getApiTokenWithTimestamp() =>
      notionAuthRepository.getApiTokenWithTimestamp();
  Future<Map<String, String?>> getDatabaseWithTimestamp() =>
      notionDatabaseRepository.getDatabaseWithTimestamp();
  Future<Map<String, String?>> getDatabaseIdWithTimestamp() =>
      notionDatabaseRepository.getDatabaseIdWithTimestamp();
  Future<Map<String, String?>> getDatabaseTitleWithTimestamp() =>
      notionDatabaseRepository.getDatabaseTitleWithTimestamp();
  Future<Map<String, String?>> getNotionInfo() =>
      notionDatabaseRepository.getNotionInfo();
  Future<String> getPageContent(String pageId) =>
      notionRepository.getPageContent(pageId);
  Future<List<dynamic>> getPagesFromDB(String databaseId) =>
      notionRepository.getPagesFromDB(databaseId);
  Future<List<Map<String, String>>> getQuizDataFromDB(String databaseId) =>
      notionRepository.getQuizDataFromDB(databaseId);
  Future<List<dynamic>> getRoadmapTasksFromDB(String databaseId) =>
      notionRepository.getRoadmapTasksFromDB(databaseId);
  Future<void> saveApiToken(String apiToken) =>
      notionAuthRepository.saveApiToken(apiToken);
  Future<void> saveDatabase(String database) =>
      notionDatabaseRepository.saveDatabase(database);
  Future<void> saveDatabaseId(String databaseId) =>
      notionDatabaseRepository.saveDatabaseId(databaseId);
  Future<void> saveDatabaseTitle(String databaseTitle) =>
      notionDatabaseRepository.saveDatabaseTitle(databaseTitle);
  Future<List<dynamic>> searchDatabases({String? query}) =>
      notionRepository.searchDatabases(query: query);

  Future<String> renderNotionDbAsMarkdown(String pageId) async {
    final blocks = await notionRepository.fetchPageBlocks(pageId);
    return notionToMarkdownConverter.convert(blocks);
  }
}
