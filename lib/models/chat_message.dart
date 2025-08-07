import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageSender { user, ai }

class ChatMessage {
  String content;
  MessageSender sender;
  DateTime timestamp;

  ChatMessage({
    required this.content,
    required this.sender,
    required this.timestamp,
  });

  // For Firestore
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      content: map['content'] as String,
      sender: map['sender'] == 'user' ? MessageSender.user : MessageSender.ai,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'sender': sender == MessageSender.user ? 'user' : 'ai',
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  // For Local Storage (JSON serializable)
  factory ChatMessage.fromLocalMap(Map<String, dynamic> map) {
    return ChatMessage(
      content: map['content'] as String,
      sender: map['sender'] == 'user' ? MessageSender.user : MessageSender.ai,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  Map<String, dynamic> toLocalMap() {
    return {
      'content': content,
      'sender': sender == MessageSender.user ? 'user' : 'ai',
      'timestamp': timestamp.toIso8601String(),
    };
  }
}