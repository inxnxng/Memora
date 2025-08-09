class ChatSession {
  final String chatId;
  final String pageTitle;
  final String databaseName;
  final DateTime lastMessageTimestamp;

  ChatSession({
    required this.chatId,
    required this.pageTitle,
    required this.databaseName,
    required this.lastMessageTimestamp,
  });

  factory ChatSession.fromMap(Map<String, dynamic> map) {
    return ChatSession(
      chatId: map['chatId'] ?? '',
      pageTitle: map['pageTitle'] ?? '',
      databaseName: map['databaseName'] ?? '',
      lastMessageTimestamp:
          DateTime.tryParse(map['lastMessageTimestamp'] ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'pageTitle': pageTitle,
      'databaseName': databaseName,
      'lastMessageTimestamp': lastMessageTimestamp.toIso8601String(),
    };
  }
}
