import 'package:memora/domain/repositories/chat_repository.dart';
import 'package:memora/models/chat_message.dart';
import 'package:memora/services/local_storage_service.dart';

class ChatRepositoryImpl implements ChatRepository {
  final LocalStorageService _localStorageService;

  ChatRepositoryImpl(this._localStorageService);

  @override
  Future<List<ChatMessage>> loadChatHistory(String taskId) async {
    final loadedHistory = await _localStorageService.loadChatHistory(taskId);
    return loadedHistory.map((msg) => ChatMessage.fromMap(msg)).toList();
  }

  @override
  Future<void> saveChatHistory(
    String taskId,
    List<ChatMessage> messages,
  ) async {
    final historyToSave = messages.map((msg) => msg.toMap()).toList();
    await _localStorageService.saveChatHistory(taskId, historyToSave);
  }

  @override
  Future<void> clearChatHistory(String taskId) async {
    await _localStorageService.saveChatHistory(taskId, []);
  }
}
