import 'package:memora/models/task_model.dart';
import 'package:memora/repositories/notion/notion_repository.dart';
import 'package:memora/services/local_storage_service.dart';

class TaskRepository {
  final NotionRepository _notionRepository;
  final LocalStorageService _localStorageService;

  TaskRepository(this._notionRepository, this._localStorageService);

  Future<List<Task>> fetchTasksFromNotion(String databaseId) async {
    try {
      final notionPages = await _notionRepository.getRoadmapTasksFromDB(
        databaseId,
      );
      final tasks = notionPages.map((json) => Task.fromNotion(json)).toList();
      tasks.sort((a, b) => a.day.compareTo(b.day));
      return tasks;
    } catch (e) {
      // Propagate error to be handled by the caller
      rethrow;
    }
  }

  Future<void> saveLastTrainedDate(String taskId, DateTime date) async {
    await _localStorageService.saveLastTrainedDate(taskId, date);
  }

  Future<DateTime?> loadLastTrainedDate(String taskId) async {
    return _localStorageService.loadLastTrainedDate(taskId);
  }
}
