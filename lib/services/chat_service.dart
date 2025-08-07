import 'package:memora/models/chat_message.dart';
import 'package:memora/models/chat_session.dart';
import 'package:memora/repositories/chat/chat_repository.dart';

class ChatService {
  final ChatRepository _chatRepository;

  ChatService(this._chatRepository);

  Stream<List<ChatMessage>> getMessages(String chatId) {
    return _chatRepository.getChatMessages(chatId);
  }

  Future<void> sendMessage(
    String chatId,
    ChatMessage message, {
    String? pageTitle,
    String? pageContent,
    String? databaseName,
  }) async {
    await _chatRepository.addChatMessage(
      chatId,
      message,
      pageTitle: pageTitle,
      pageContent: pageContent,
      databaseName: databaseName,
    );
  }

  Future<List<ChatSession>> getAllChatSessions() {
    return _chatRepository.getAllChatSessions();
  }

  Future<Map<String, List<ChatMessage>>> getAllChatHistories() {
    return _chatRepository.getAllChatHistories();
  }
}
