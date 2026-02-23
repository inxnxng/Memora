class NotionPage {
  final String id;
  final String title;
  final String content;
  final String? url;
  final DateTime createdTime;

  NotionPage({
    required this.id,
    required this.title,
    required this.content,
    this.url,
    required this.createdTime,
  });

  factory NotionPage.fromMap(Map<String, dynamic> map) {
    final properties = map['properties'] as Map<String, dynamic>;

    // Find the 'title' property dynamically, as its name can vary.
    final titlePropertyKey = properties.keys.firstWhere(
      (k) => properties[k]['type'] == 'title',
      orElse: () => '',
    );

    String title = 'Untitled';
    if (titlePropertyKey.isNotEmpty) {
      final titleProperty =
          properties[titlePropertyKey]?['title'] as List<dynamic>?;
      if (titleProperty != null && titleProperty.isNotEmpty) {
        title = titleProperty[0]['plain_text'] as String;
      }
    }

    final content = '';
    final url = map['url'] as String?;
    final createdTime = DateTime.parse(map['created_time'] as String);

    return NotionPage(
      id: map['id'] as String,
      title: title,
      content: content,
      url: url,
      createdTime: createdTime,
    );
  }
}
