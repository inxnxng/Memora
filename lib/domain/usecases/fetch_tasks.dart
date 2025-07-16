import 'package:memora/domain/repositories/task_repository.dart';
import 'package:memora/models/task_model.dart';

class FetchTasks {
  final TaskRepository repository;

  FetchTasks(this.repository);

  Future<List<Task>> call() {
    return repository.fetchTasks();
  }
}
