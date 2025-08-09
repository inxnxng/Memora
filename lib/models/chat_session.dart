import 'package:cloud_firestore/cloud_firestore.dart';

class ChatSession {
  final String chatId;
  final String pageTitle;
  final String pageContent;
  final String databaseName;
  final DateTime lastMessageTimestamp;

  ChatSession({
    required this.chatId,
    required this.pageTitle,
    required this.pageContent,
    required this.databaseName,
    required this.lastMessageTimestamp,
  });

  factory ChatSession.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatSession(
      chatId: doc.id,
      pageTitle: data['pageTitle'] ?? '',
      pageContent: data['pageContent'] ?? '',
      databaseName: data['databaseName'] ?? '',
      lastMessageTimestamp: (data['lastMessageTimestamp'] as Timestamp)
          .toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'pageTitle': pageTitle,
      'pageContent': pageContent,
      'databaseName': databaseName,
      'lastMessageTimestamp': Timestamp.fromDate(lastMessageTimestamp),
    };
  }
}
