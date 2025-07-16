import 'package:memora/domain/repositories/chat_repository.dart';
import 'package:memora/models/chat_message.dart';

class SaveChatHistory {
  final ChatRepository repository;

  SaveChatHistory(this.repository);

  Future<void> call(String taskId, List<ChatMessage> messages) {
    return repository.saveChatHistory(taskId, messages);
  }
}
