import 'package:memora/domain/repositories/notion_database_repository.dart';

class GetNotionDatabase {
  final NotionDatabaseRepository repository;

  GetNotionDatabase(this.repository);

  Future<Map<String, String?>> call() {
    return repository.getDatabaseWithTimestamp();
  }
}
