import 'dart:math';

import 'package:memora/constants/task_list.dart';
import 'package:memora/models/task_model.dart';
import 'package:memora/repositories/task/task_repository.dart';

class TaskService {
  final TaskRepository _repository;
  final int _totalDays = 30;

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

    if (fetchedTasks.isEmpty || fetchedTasks.length < _totalDays) {
      fetchedTasks = _generateLocalTasks(fetchedTasks);
    }

    for (var task in fetchedTasks) {
      task.lastTrainedDate = await loadLastTrainedDate(task.id);
    }

    return fetchedTasks;
  }

  List<Task> _generateLocalTasks(List<Task> existingTasks) {
    final Map<int, Task> taskMap = {
      for (var task in existingTasks) task.day: task,
    };
    return List<Task>.generate(_totalDays, (index) {
      final dayNumber = index + 1;
      if (taskMap.containsKey(dayNumber)) {
        return taskMap[dayNumber]!;
      } else {
        final taskDetail = dailyTasks[Random().nextInt(dailyTasks.length)];
        return Task(
          id: 'day$dayNumber',
          title: 'Day $dayNumber: ${taskDetail['title']}',
          description: taskDetail['description'] ?? '',
          day: dayNumber,
          isCompleted: false,
          lastTrainedDate: null,
        );
      }
    });
  }

  Future<DateTime?> loadLastTrainedDate(String taskId) =>
      _repository.loadLastTrainedDate(taskId);

  Future<void> saveLastTrainedDate(String taskId, DateTime date) =>
      _repository.saveLastTrainedDate(taskId, date);
}
