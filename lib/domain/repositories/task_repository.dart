import 'package:memora/models/task_model.dart';

abstract class TaskRepository {
  Future<List<Task>> fetchTasks();
  Future<void> toggleTaskCompletion(String taskId, bool isCompleted);
  Future<void> saveLastTrainedDate(String taskId, DateTime date);
  Future<DateTime?> loadLastTrainedDate(String taskId);
}
