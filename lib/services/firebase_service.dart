import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:memora/models/chat_message.dart';
import 'package:memora/models/chat_session.dart';
import 'package:memora/models/task_model.dart';
import 'package:memora/models/user_model.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<void> signInAnonymously() async {
    if (currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  // Method to add a chat message and update the session.
  Future<void> addChatMessage(
    String chatId,
    ChatMessage message, {
    String? pageTitle,
    String? pageContent,
    String? databaseName,
  }) async {
    if (currentUser == null) return;
    final userDocRef = _firestore.collection('users').doc(currentUser!.uid);
    final chatSessionRef = userDocRef.collection('chats').doc(chatId);

    // Use a batch to perform multiple operations atomically.
    final batch = _firestore.batch();

    // 1. Add the new message.
    batch.set(
      chatSessionRef.collection('messages').doc(), // Auto-generate message ID
      message.toMap(),
    );

    // 2. Create or update the chat session metadata.
    final sessionData = {
      'lastMessageTimestamp': message.timestamp,
      'pageTitle': pageTitle,
      'pageContent': pageContent,
      'databaseName': databaseName,
    };
    // Use set with merge:true to create or update the document.
    batch.set(chatSessionRef, sessionData, SetOptions(merge: true));

    await batch.commit();
  }

  // Method to get a stream of chat messages for a specific chat session
  Stream<QuerySnapshot> getChatMessagesStream(String chatId) {
    if (currentUser == null) {
      throw Exception("User not logged in");
    }
    return _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Method to get all chat sessions for the current user.
  Future<List<ChatSession>> getAllChatSessions() async {
    if (currentUser == null) return [];
    final snapshot = await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('chats')
        .orderBy('lastMessageTimestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) => ChatSession.fromFirestore(doc)).toList();
  }

  // Method to delete a specific chat session and all its messages.
  Future<void> deleteChatSession(String chatId) async {
    if (currentUser == null) return;
    final chatSessionRef = _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('chats')
        .doc(chatId);

    // Delete all messages in the subcollection first.
    final messagesSnapshot = await chatSessionRef.collection('messages').get();
    for (var doc in messagesSnapshot.docs) {
      await doc.reference.delete();
    }

    // Then delete the chat session document itself.
    await chatSessionRef.delete();
  }

  Future<void> saveTasks(List<Task> tasks) async {
    if (currentUser == null) return;
    final userDoc = _firestore.collection('users').doc(currentUser!.uid);
    final batch = _firestore.batch();

    for (var task in tasks) {
      batch.set(userDoc.collection('tasks').doc(task.id), {
        'title': task.title,
        'description': task.description,
        'day': task.day,
        'isCompleted': task.isCompleted,
      });
    }
    await batch.commit();
  }

  Future<List<Task>> getTasks() async {
    if (currentUser == null) return [];
    final snapshot = await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('tasks')
        .orderBy('day')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Task(
        id: doc.id,
        title: data['title'] ?? '',
        description: data['description'] ?? '',
        day: data['day'] ?? 0,
        isCompleted: data['isCompleted'] ?? false,
      );
    }).toList();
  }

  Future<void> updateTaskCompletion(String taskId, bool isCompleted) async {
    if (currentUser == null) return;
    await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('tasks')
        .doc(taskId)
        .update({'isCompleted': isCompleted});
  }

  Future<void> updateUserProfile(String name, double progress) async {
    if (currentUser == null) return;
    await _firestore.collection('users').doc(currentUser!.uid).set({
      'displayName': name,
      'progress': progress,
    }, SetOptions(merge: true));
  }

  Future<List<AppUser>> getRanking() async {
    final snapshot = await _firestore
        .collection('users')
        .orderBy('progress', descending: true)
        .limit(100)
        .get();
    return snapshot.docs
        .map((doc) => AppUser.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<AppUser?> getCurrentUser() async {
    if (currentUser == null) return null;
    final doc = await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.id, doc.data()!);
  }
}
