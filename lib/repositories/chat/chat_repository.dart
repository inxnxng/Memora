import 'dart:async';

import 'package:memora/models/chat_message.dart';
import 'package:memora/models/chat_session.dart';
import 'package:memora/services/firebase_service.dart';
import 'package:memora/services/local_storage_service.dart';

/// Gets a stream of chat messages.
///
/// This stream first emits the locally cached messages, then listens for
/// real-time updates from Firebase. When an update is received, it updates
/// the local cache and emits the new list of messages.

class ChatRepository {
  final FirebaseService _firebaseService;
  final LocalStorageService _localStorageService;

  ChatRepository(this._firebaseService, this._localStorageService);

  /// Generates a unique and consistent chatId from a list of page IDs.
  static String generateChatId(List<String> pageIds) {
    if (pageIds.isEmpty) {
      return '';
    }
    // Sort IDs to ensure consistency regardless of original order
    pageIds.sort();
    return pageIds.join('-');
  }

  /// Adds a chat message to Firebase and updates the chat session metadata.
  Future<void> addChatMessage(
    String chatId,
    ChatMessage message, {
    String? pageTitle,
    String? pageContent,
    String? databaseName,
  }) async {
    await _firebaseService.addChatMessage(
      chatId,
      message,
      pageTitle: pageTitle,
      pageContent: pageContent,
      databaseName: databaseName,
    );
  }

  /// Gets a stream of chat messages.
  ///
  /// This stream first emits the locally cached messages, then listens for
  /// real-time updates from Firebase. When an update is received, it updates
  /// the local cache and emits the new list of messages.
  Stream<List<ChatMessage>> getChatMessages(String chatId) {
    final controller = StreamController<List<ChatMessage>>();
    late StreamSubscription<List<ChatMessage>> firebaseSubscription;

    // 1. Load initial data from local storage and emit it.
    _localStorageService
        .loadChatHistory(chatId)
        .then((messages) {
          if (!controller.isClosed) {
            controller.add(messages);
          }
        })
        .catchError((error) {
          if (!controller.isClosed) {
            controller.addError('Failed to load local chat history: $error');
          }
        });

    // 2. Listen to the Firebase stream for real-time updates.
    final firebaseStream = _firebaseService.getChatMessagesStream(chatId).map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        return ChatMessage.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });

    firebaseSubscription = firebaseStream.listen(
      (messages) {
        // 3. When Firebase data comes in, update local storage.
        _localStorageService.saveChatHistory(chatId, messages);

        // 4. Emit the updated list to the UI.
        if (!controller.isClosed) {
          controller.add(messages);
        }
      },
      onError: (error) {
        if (!controller.isClosed) {
          controller.addError('Failed to get messages from Firebase: $error');
        }
      },
    );

    // When the stream listener is cancelled, close the subscription.
    controller.onCancel = () {
      firebaseSubscription.cancel();
      controller.close();
    };

    return controller.stream;
  }

  /// Gets all chat sessions from Firebase.
  Future<List<ChatSession>> getAllChatSessions() async {
    return await _firebaseService.getAllChatSessions();
  }

  /// Gets all chat histories stored locally.
  Future<Map<String, List<ChatMessage>>> getAllChatHistories() async {
    final allKeys = await _localStorageService.getAllChatHistoryKeys();
    final Map<String, List<ChatMessage>> allHistories = {};

    for (final key in allKeys) {
      final messages = await _localStorageService.loadChatHistory(key);
      // Extract the original chatId from the storage key
      final chatId = _localStorageService.getOriginalKey(key);
      allHistories[chatId] = messages;
    }
    return allHistories;
  }
}
