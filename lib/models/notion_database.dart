class NotionDatabase {
  final String id;
  final String title;

  NotionDatabase({required this.id, required this.title});

  factory NotionDatabase.fromMap(Map<String, dynamic> map) {
    final titleProperty = map['title'] as List<dynamic>?;
    final title = titleProperty != null && titleProperty.isNotEmpty
        ? titleProperty[0]['plain_text'] as String
        : 'Untitled Database';

    return NotionDatabase(id: map['id'] as String, title: title);
  }
}
