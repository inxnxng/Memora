import 'package:memora/domain/usecases/chat_usecases.dart';
import 'package:memora/models/chat_message.dart';

class ChatService {
  final ChatUsecases _chatUsecases;

  ChatService(this._chatUsecases);

  Future<List<ChatMessage>> loadChatHistory(String taskId) async {
    return await _chatUsecases.loadChatHistory(taskId);
  }

  Future<void> saveChatHistory(
    String taskId,
    List<ChatMessage> messages,
  ) async {
    await _chatUsecases.saveChatHistory(taskId, messages);
  }

  Future<void> clearChatHistory(String taskId) async {
    await _chatUsecases.clearChatHistory(taskId);
  }
}
