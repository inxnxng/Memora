import 'package:memora/domain/repositories/notion_repository.dart';

class GetDatabaseInfo {
  final NotionRepository repository;

  GetDatabaseInfo(this.repository);

  Future<Map<String, dynamic>> call(String databaseId) {
    return repository.getDatabaseInfo(databaseId);
  }
}
