import 'package:memora/domain/repositories/notion_database_repository.dart';

class ClearNotionDatabaseInfo {
  final NotionDatabaseRepository repository;

  ClearNotionDatabaseInfo(this.repository);

  Future<void> call() {
    return repository.clearDatabaseInfo();
  }
}
