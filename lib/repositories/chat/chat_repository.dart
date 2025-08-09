import 'dart:async';

import 'package:memora/models/chat_message.dart';
import 'package:memora/models/chat_session.dart';
import 'package:memora/services/local_storage_service.dart';

class ChatRepository {
  final LocalStorageService _localStorageService;

  ChatRepository(this._localStorageService);

  static String generateChatId(List<String> pageIds) {
    if (pageIds.isEmpty) {
      return '';
    }
    pageIds.sort();
    return pageIds.join('-');
  }

  Future<void> addChatMessage(
    String chatId,
    ChatMessage message, {
    String? pageTitle,
    String? databaseName,
  }) async {
    final existingMessages = await _localStorageService
        .loadChatHistory(chatId)
        .first;
    final updatedMessages = [message, ...existingMessages];
    await _localStorageService.saveChatHistory(chatId, updatedMessages);

    if (pageTitle != null) {
      await _localStorageService.saveChatSession(
        chatId,
        pageTitle,
        message.timestamp,
        databaseName,
      );
    }
  }

  Stream<List<ChatMessage>> getChatMessages(String chatId) {
    return _localStorageService.loadChatHistory(chatId).map((messages) {
      messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return messages;
    });
  }

  Future<List<ChatSession>> getAllChatSessions() async {
    return await _localStorageService.getAllChatSessions();
  }

  Future<Map<String, List<ChatMessage>>> getAllChatHistories() async {
    final allKeys = await _localStorageService.getAllChatHistoryKeys();
    final Map<String, List<ChatMessage>> allHistories = {};

    for (final key in allKeys) {
      final messages = await _localStorageService.loadChatHistory(key).first;
      final chatId = _localStorageService.getOriginalKey(key);
      allHistories[chatId] = messages;
    }
    return allHistories;
  }

  Future<void> deleteChatSessions(List<String> chatIds) async {
    for (String chatId in chatIds) {
      await _localStorageService.deleteChatHistory(chatId);
      await _localStorageService.deleteChatSession(chatId);
    }
  }

  Future<void> deleteAllChatSessions() async {
    final allKeys = await _localStorageService.getAllChatHistoryKeys();
    final chatIds = allKeys
        .map((key) => _localStorageService.getOriginalKey(key))
        .toList();
    await deleteChatSessions(chatIds);
  }
}
