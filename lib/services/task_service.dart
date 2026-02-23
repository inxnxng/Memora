import 'package:memora/models/task_model.dart';
import 'package:memora/repositories/task/task_repository.dart';

class TaskService {
  final TaskRepository _repository;

  TaskService(this._repository);

  Future<List<Task>> getTasks(String? databaseId) async {
    List<Task> fetchedTasks = [];

    if (databaseId != null &&
        databaseId.isNotEmpty &&
        databaseId != 'YOUR_NOTION_DATABASE_ID') {
      try {
        fetchedTasks = await _repository.fetchTasksFromNotion(databaseId);
      } catch (e) {
        // Ignore error and proceed to local generation.
      }
    }

    for (var task in fetchedTasks) {
      task.lastTrainedDate = await loadLastTrainedDate(task.id);
    }

    return fetchedTasks;
  }

  Future<DateTime?> loadLastTrainedDate(String taskId) =>
      _repository.loadLastTrainedDate(taskId);

  Future<void> saveLastTrainedDate(String taskId, DateTime date) =>
      _repository.saveLastTrainedDate(taskId, date);

  Future<void> addStudyRecordForToday({
    String? databaseName,
    required String title,
    String? pageId,
    String? url,
  }) async {
    await _repository.addStudyRecord(
      DateTime.now(),
      databaseName: databaseName,
      title: title,
      pageId: pageId,
      url: url,
    );
  }

  Future<Map<DateTime, List<Map<String, dynamic>>>> getHeatmapData() async {
    return await _repository.getStudyRecords();
  }

  Future<Set<String>> getCompletedPageIds() async {
    return await _repository.getCompletedPageIds();
  }
}
