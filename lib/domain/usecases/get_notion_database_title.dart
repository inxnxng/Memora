import 'package:memora/domain/repositories/notion_database_repository.dart';

class GetNotionDatabaseTitle {
  final NotionDatabaseRepository repository;

  GetNotionDatabaseTitle(this.repository);

  Future<Map<String, String?>> call() {
    return repository.getDatabaseTitleWithTimestamp();
  }
}
