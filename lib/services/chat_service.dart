import 'package:memora/models/chat_message.dart';
import 'package:memora/repositories/chat/chat_repository.dart';

class ChatService {
  final ChatRepository _chatRepository;

  ChatService(this._chatRepository);

  Future<List<ChatMessage>> loadChatHistory(String taskId) =>
      _chatRepository.loadChatHistory(taskId);

  Future<void> saveChatHistory(String taskId, List<ChatMessage> messages) =>
      _chatRepository.saveChatHistory(taskId, messages);

  Future<void> clearChatHistory(String taskId) =>
      _chatRepository.clearChatHistory(taskId);
}
