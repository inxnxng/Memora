import 'package:memora/domain/repositories/notion_database_repository.dart';

class GetNotionDatabaseId {
  final NotionDatabaseRepository repository;

  GetNotionDatabaseId(this.repository);

  Future<Map<String, String?>> call() {
    return repository.getDatabaseIdWithTimestamp();
  }
}
