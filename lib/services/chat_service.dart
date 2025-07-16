import 'package:memora/models/chat_message.dart';
import 'package:memora/domain/usecases/load_chat_history.dart';
import 'package:memora/domain/usecases/save_chat_history.dart';
import 'package:memora/domain/usecases/clear_chat_history.dart';

class ChatService {
  final LoadChatHistory _loadChatHistory;
  final SaveChatHistory _saveChatHistory;
  final ClearChatHistory _clearChatHistory;

  ChatService(
    this._loadChatHistory,
    this._saveChatHistory,
    this._clearChatHistory,
  );

  Future<List<ChatMessage>> loadChatHistory(String taskId) async {
    return await _loadChatHistory.call(taskId);
  }

  Future<void> saveChatHistory(
    String taskId,
    List<ChatMessage> messages,
  ) async {
    await _saveChatHistory.call(taskId, messages);
  }

  Future<void> clearChatHistory(String taskId) async {
    await _clearChatHistory.call(taskId);
  }
}
