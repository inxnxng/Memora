import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

enum MessageSender { user, ai, system }

class ChatMessage {
  final String id;
  String content;
  MessageSender sender;
  DateTime timestamp;

  ChatMessage({
    required this.content,
    required this.sender,
    required this.timestamp,
    String? id,
  }) : id = id ?? const Uuid().v4();

  // For Firestore
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String?,
      content: map['content'] as String,
      sender: map['sender'] == 'user' ? MessageSender.user : MessageSender.ai,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'sender': sender == MessageSender.user ? 'user' : 'ai',
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  // For Local Storage (JSON serializable)
  factory ChatMessage.fromLocalMap(Map<String, dynamic> map) {
    final senderStr = map['sender'] as String?;
    final sender = senderStr == 'user'
        ? MessageSender.user
        : senderStr == 'system'
        ? MessageSender.system
        : MessageSender.ai;
    return ChatMessage(
      id: map['id'] as String?,
      content: map['content'] as String,
      sender: sender,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  Map<String, dynamic> toLocalMap() {
    final senderStr = sender == MessageSender.user
        ? 'user'
        : sender == MessageSender.system
        ? 'system'
        : 'ai';
    return {
      'id': id,
      'content': content,
      'sender': senderStr,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
