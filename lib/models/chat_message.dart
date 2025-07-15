enum MessageSender { user, ai }

class ChatMessage {
  final String content;
  final MessageSender sender;
  final DateTime timestamp;

  ChatMessage({
    required this.content,
    required this.sender,
    required this.timestamp,
  });

  // Factory constructor to create a ChatMessage from a map (e.g., from local storage)
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      content: map['content'] as String,
      sender: map['role'] == 'user' ? MessageSender.user : MessageSender.ai,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  // Convert ChatMessage to a map for storage
  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'role': sender == MessageSender.user ? 'user' : 'ai',
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
