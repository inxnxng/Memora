class NotionPage {
  final String id;
  final String title;
  final String content;

  NotionPage({required this.id, required this.title, required this.content});

  factory NotionPage.fromMap(Map<String, dynamic> map) {
    final properties = map['properties'] as Map<String, dynamic>;
    final titleProperty = properties['Name']?['title'] as List<dynamic>?;
    final title = titleProperty != null && titleProperty.isNotEmpty
        ? titleProperty[0]['plain_text'] as String
        : 'Untitled';

    final content = '';

    return NotionPage(id: map['id'] as String, title: title, content: content);
  }
}
