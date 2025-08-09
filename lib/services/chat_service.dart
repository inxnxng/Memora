import 'package:memora/constants/prompt_constants.dart';
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
    String? databaseName,
  }) async {
    await _chatRepository.addChatMessage(
      chatId,
      message,
      pageTitle: pageTitle,
      databaseName: databaseName,
    );
  }

  List<Map<String, String>> buildPromptForAI(
    List<ChatMessage> history,
    String pageContents,
    String pageTitles,
  ) {
    final userMessages = history
        .where((m) => m.sender == MessageSender.user)
        .toList();

    final isFirstUserMessage = userMessages.length == 1;

    if (isFirstUserMessage) {
      return [
        {'role': 'system', 'content': PromptConstants.reviewSystemPrompt},
        {
          'role': 'user',
          'content': PromptConstants.initialUserPrompt(pageContents),
        },
      ];
    } else {
      final chatHistory = history.reversed
          .take(10)
          .toList()
          // .where((m) => m.content != PromptConstants.welcomeMessage(pageTitles))
          .map(
            (msg) => {
              'role': msg.sender == MessageSender.user ? 'user' : 'assistant',
              'content': msg.content,
            },
          )
          .toList();

      return [
        {'role': 'system', 'content': PromptConstants.reviewSystemPrompt},
        ...chatHistory,
      ];
    }
  }

  Future<List<ChatSession>> getAllChatSessions() {
    return _chatRepository.getAllChatSessions();
  }

  Future<Map<String, List<ChatMessage>>> getAllChatHistories() {
    return _chatRepository.getAllChatHistories();
  }

  Future<void> deleteChatSessions(List<String> chatIds) {
    return _chatRepository.deleteChatSessions(chatIds);
  }

  Future<void> deleteAllChatSessions() {
    return _chatRepository.deleteAllChatSessions();
  }
}
