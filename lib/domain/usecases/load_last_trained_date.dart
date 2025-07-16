import 'package:memora/domain/repositories/task_repository.dart';

class LoadLastTrainedDate {
  final TaskRepository repository;

  LoadLastTrainedDate(this.repository);

  Future<DateTime?> call(String taskId) {
    return repository.loadLastTrainedDate(taskId);
  }
}
