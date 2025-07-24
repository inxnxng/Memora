import 'package:memora/models/task_model.dart';
import 'package:memora/repositories/task_repository.dart';

class TaskUsecases {
  final TaskRepository repository;

  TaskUsecases(this.repository);

  Future<List<Task>> fetchTasks() => repository.fetchTasks();
  Future<DateTime?> loadLastTrainedDate(String taskId) =>
      repository.loadLastTrainedDate(taskId);
  Future<void> saveLastTrainedDate(String taskId, DateTime date) =>
      repository.saveLastTrainedDate(taskId, date);
  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) =>
      repository.toggleTaskCompletion(taskId, isCompleted);
}
