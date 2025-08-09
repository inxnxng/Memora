import 'package:memora/models/notion_page.dart';
import 'package:memora/models/task_model.dart';
import 'package:memora/repositories/notion/notion_repository.dart';
import 'package:memora/services/local_storage_service.dart';

class TaskRepository {
  final NotionRepository _notionRepository;
  final LocalStorageService _localStorageService;

  TaskRepository(this._notionRepository, this._localStorageService);

  Future<List<Task>> fetchTasksFromNotion(String databaseId) async {
    try {
      final dbInfo = await _notionRepository.getDatabaseInfo(databaseId);
      final dbTitleProperty = dbInfo['title'] as List<dynamic>?;
      final databaseName = dbTitleProperty != null && dbTitleProperty.isNotEmpty
          ? dbTitleProperty[0]['plain_text'] as String
          : 'Untitled DB';

      final notionResponse = await _notionRepository.getRoadmapTasksFromDB(
        databaseId,
      );
      final notionPages = (notionResponse['results'] as List)
          .map((json) => NotionPage.fromMap(json))
          .toList();
      final tasks = notionPages
          .map((page) => Task.fromNotionPage(page, databaseName: databaseName))
          .toList();
      tasks.sort((a, b) => a.day.compareTo(b.day));
      return tasks;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> saveLastTrainedDate(String taskId, DateTime date) async {
    await _localStorageService.saveLastTrainedDate(taskId, date);
  }

  Future<DateTime?> loadLastTrainedDate(String taskId) async {
    return _localStorageService.loadLastTrainedDate(taskId);
  }

  Future<void> addStudyRecord(
    DateTime date, {
    String? databaseName,
    required String title,
  }) async {
    await _localStorageService.addStudyRecord(
      date,
      databaseName: databaseName,
      title: title,
    );
  }

  Future<Map<DateTime, List<Map<String, dynamic>>>> getStudyRecords() async {
    return await _localStorageService.getStudyRecords();
  }
}
