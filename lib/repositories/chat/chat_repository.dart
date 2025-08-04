import 'package:memora/models/chat_message.dart';
import 'package:memora/services/firebase_service.dart';

class ChatRepository {
  final FirebaseService _firebaseService;

  ChatRepository(this._firebaseService);

  Future<void> addChatMessage(String chatId, ChatMessage message) async {
    await _firebaseService.addChatMessage(chatId, message);
  }

  Stream<List<ChatMessage>> getChatMessages(String chatId) {
    return _firebaseService.getChatMessagesStream(chatId).map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ChatMessage.fromMap(data);
      }).toList();
    });
  }
}
