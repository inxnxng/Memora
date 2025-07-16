import 'package:memora/domain/repositories/notion_database_repository.dart';

class SaveNotionDatabaseTitle {
  final NotionDatabaseRepository repository;

  SaveNotionDatabaseTitle(this.repository);

  Future<void> call(String databaseTitle) {
    return repository.saveDatabaseTitle(databaseTitle);
  }
}
