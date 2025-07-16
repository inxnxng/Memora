import 'package:memora/domain/repositories/notion_database_repository.dart';

class GetNotionInfo {
  final NotionDatabaseRepository repository;

  GetNotionInfo(this.repository);

  Future<Map<String, String?>> call() {
    return repository.getNotionInfo();
  }
}
