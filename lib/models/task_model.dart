class Task {
  final String id;
  final String title;
  final String description;
  final int day;
  bool isCompleted;
  DateTime? lastTrainedDate; // New field

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.day,
    this.isCompleted = false,
    this.lastTrainedDate, // New parameter
  });

  factory Task.fromNotion(Map<String, dynamic> json) {
    final properties = json['properties'];
    final titleProperty = properties['Name']?['title'] as List<dynamic>?;
    final title = titleProperty != null && titleProperty.isNotEmpty
        ? titleProperty[0]['plain_text'] as String
        : 'Untitled';

    final descriptionProperty =
        properties['Description']?['rich_text'] as List<dynamic>?;
    final description =
        descriptionProperty != null && descriptionProperty.isNotEmpty
        ? descriptionProperty[0]['plain_text'] as String
        : '';

    final dayProperty = properties['Day']?['number'] as int?;
    final day = dayProperty ?? 0; // Default to 0 if not found

    final isCompletedProperty = properties['Completed']?['checkbox'] as bool?;
    final isCompleted = isCompletedProperty ?? false;

    return Task(
      id: json['id'] as String,
      title: title,
      description: description,
      day: day,
      isCompleted: isCompleted,
    );
  }
}

class NotionPage {
  final String id;
  final String title;
  final String content;

  NotionPage({required this.id, required this.title, required this.content});
}
