import 'package:memora/models/chat_message.dart';
import 'package:memora/repositories/chat_repository.dart';

class ChatUsecases {
  final ChatRepository repository;

  ChatUsecases(this.repository);

  Future<void> clearChatHistory(String taskId) =>
      repository.clearChatHistory(taskId);
  Future<List<ChatMessage>> loadChatHistory(String taskId) =>
      repository.loadChatHistory(taskId);
  Future<void> saveChatHistory(String taskId, List<ChatMessage> messages) =>
      repository.saveChatHistory(taskId, messages);
}
