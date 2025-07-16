import 'package:memora/domain/repositories/task_repository.dart';

class ToggleTaskCompletion {
  final TaskRepository repository;

  ToggleTaskCompletion(this.repository);

  Future<void> call(String taskId, bool isCompleted) {
    return repository.toggleTaskCompletion(taskId, isCompleted);
  }
}
