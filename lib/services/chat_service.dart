import 'package:memora/models/chat_message.dart';
import 'package:memora/repositories/chat/chat_repository.dart';

class ChatService {
  final ChatRepository _chatRepository;

  ChatService(this._chatRepository);

  Stream<List<ChatMessage>> getMessages(String chatId) {
    return _chatRepository.getChatMessages(chatId);
  }

  Future<void> sendMessage(String chatId, ChatMessage message) async {
    await _chatRepository.addChatMessage(chatId, message);
  }
}
