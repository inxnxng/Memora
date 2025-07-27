import 'package:memora/repositories/notion/notion_auth_repository.dart';
import 'package:memora/repositories/notion/notion_database_repository.dart';
import 'package:memora/repositories/notion/notion_repository.dart';
import 'package:memora/services/notion_to_markdown_converter.dart';

class NotionService {
  final NotionAuthRepository notionAuthRepository;
  final NotionDatabaseRepository notionDatabaseRepository;
  final NotionRepository notionRepository;
  final NotionToMarkdownConverter notionToMarkdownConverter;

  NotionService({
    required this.notionAuthRepository,
    required this.notionDatabaseRepository,
    required this.notionRepository,
  }) : notionToMarkdownConverter = NotionToMarkdownConverter();

  // --- Connection and Initialization ---

  Future<Map<String, String?>> initializeConnection() async {
    final tokenData = await notionAuthRepository.getApiKeyWithTimestamp();
    final databaseData = await notionDatabaseRepository.getDatabaseInfo();

    return {
      'apiToken': tokenData['value'],
      'apiTokenTimestamp': tokenData['timestamp'],
      'databaseId': databaseData['id'],
      'databaseTitle': databaseData['title'],
    };
  }

  Future<Map<String, String>> connectDatabase(
    String databaseId,
    String databaseTitle,
  ) async {
    await notionDatabaseRepository.saveDatabaseInfo(databaseId, databaseTitle);
    return {'databaseId': databaseId, 'databaseTitle': databaseTitle};
  }

  // --- API Key Management ---

  Future<void> updateApiToken(String apiToken) {
    return notionAuthRepository.saveApiKeyWithTimestamp(apiToken);
  }

  Future<Map<String, String?>> getApiKeyWithTimestamp() {
    return notionAuthRepository.getApiKeyWithTimestamp();
  }

  Future<void> saveApiKeyWithTimestamp(String apiToken) {
    return notionAuthRepository.saveApiKeyWithTimestamp(apiToken);
  }

  // --- Database Operations ---

  Future<List<dynamic>> searchDatabases({String? query}) {
    return notionRepository.searchDatabases(query: query);
  }

  Future<List<dynamic>> getPagesFromDB(String databaseId) {
    return notionRepository.getPagesFromDB(databaseId);
  }

  // --- Page Content ---

  Future<String> getPageContent(String pageId) {
    return notionRepository.getPageContent(pageId);
  }

  Future<String> renderNotionDbAsMarkdown(String pageId) async {
    final blocks = await notionRepository.fetchPageBlocks(pageId);
    return notionToMarkdownConverter.convert(blocks);
  }
}
