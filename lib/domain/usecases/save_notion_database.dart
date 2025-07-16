import 'package:memora/domain/repositories/notion_database_repository.dart';

class SaveNotionDatabase {
  final NotionDatabaseRepository repository;

  SaveNotionDatabase(this.repository);

  Future<void> call(String database) {
    return repository.saveDatabase(database);
  }
}
