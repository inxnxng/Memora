import 'package:memora/domain/repositories/chat_repository.dart';

class ClearChatHistory {
  final ChatRepository repository;

  ClearChatHistory(this.repository);

  Future<void> call(String taskId) {
    return repository.clearChatHistory(taskId);
  }
}
