import 'package:memora/domain/repositories/chat_repository.dart';
import 'package:memora/models/chat_message.dart';

class LoadChatHistory {
  final ChatRepository repository;

  LoadChatHistory(this.repository);

  Future<List<ChatMessage>> call(String taskId) {
    return repository.loadChatHistory(taskId);
  }
}
