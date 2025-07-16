import 'package:memora/domain/repositories/notion_repository.dart';

class GetPagesFromDB {
  final NotionRepository repository;

  GetPagesFromDB(this.repository);

  Future<List<dynamic>> call(String databaseId) {
    return repository.getPagesFromDB(databaseId);
  }
}
