import 'package:memora/domain/repositories/notion_database_repository.dart';

class SaveNotionDatabaseId {
  final NotionDatabaseRepository repository;

  SaveNotionDatabaseId(this.repository);

  Future<void> call(String databaseId) {
    return repository.saveDatabaseId(databaseId);
  }
}
