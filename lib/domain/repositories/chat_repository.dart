import 'package:memora/models/chat_message.dart';

abstract class ChatRepository {
  Future<List<ChatMessage>> loadChatHistory(String taskId);
  Future<void> saveChatHistory(String taskId, List<ChatMessage> messages);
  Future<void> clearChatHistory(String taskId);
}
