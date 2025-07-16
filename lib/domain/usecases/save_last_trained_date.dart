import 'package:memora/domain/repositories/task_repository.dart';

class SaveLastTrainedDate {
  final TaskRepository repository;

  SaveLastTrainedDate(this.repository);

  Future<void> call(String taskId, DateTime date) {
    return repository.saveLastTrainedDate(taskId, date);
  }
}
