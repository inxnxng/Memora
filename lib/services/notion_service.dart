import 'package:memora/models/notion_page.dart';
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
    required this.notionToMarkdownConverter,
  });

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

  Future<bool> checkApiKeyAvailability() async {
    final keyData = await notionAuthRepository.getApiKeyWithTimestamp();
    if (keyData['value'] == null || keyData['value']!.isEmpty) {
      return false;
    }
    final isValid = await notionAuthRepository.getApiKeyValidStatus();
    return isValid ?? false;
  }

  Future<bool> validateAndSaveApiKey(String apiToken) async {
    final isValid = await notionRepository.validateApiKey(apiToken);
    await notionAuthRepository.saveApiKeyValidStatus(isValid);
    if (isValid) {
      await notionAuthRepository.saveApiKeyWithTimestamp(apiToken);
    }
    return isValid;
  }

  Future<void> updateApiToken(String apiToken) async {
    await validateAndSaveApiKey(apiToken);
  }

  Future<Map<String, String?>> getApiKeyWithTimestamp() {
    return notionAuthRepository.getApiKeyWithTimestamp();
  }

  Future<void> saveApiKeyWithTimestamp(String apiToken) async {
    await validateAndSaveApiKey(apiToken);
  }

  Future<void> deleteApiKey() {
    return notionAuthRepository.deleteApiKey();
  }

  // --- Database Operations ---

  Future<Map<String, dynamic>> searchDatabases({String? query}) {
    return notionRepository.searchDatabases(query: query);
  }

  Future<Map<String, dynamic>> getPagesFromDB(
    String databaseId, [
    String? startCursor,
  ]) {
    return notionRepository.getPagesFromDB(databaseId, startCursor);
  }

  // --- Page Content ---

  Future<String> getPageContent(String pageId) {
    return notionRepository.getPageContent(pageId);
  }

  Future<String> renderNotionDbAsMarkdown(String pageId) async {
    final response = await notionRepository.fetchPageBlocks(pageId);
    final blocks = response['results'] as List<dynamic>;
    if (blocks.isEmpty) {
      return '';
    }
    return notionToMarkdownConverter.convert(blocks);
  }

  Future<NotionPage?> fetchPageById(String pageId) async {
    try {
      final content = await getPageContent(pageId);
      return NotionPage(id: pageId, title: "Fetched Page", content: content);
    } catch (e) {
      return null;
    }
  }
}
