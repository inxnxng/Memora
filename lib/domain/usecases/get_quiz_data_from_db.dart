import 'package:memora/domain/repositories/notion_repository.dart';

class GetQuizDataFromDB {
  final NotionRepository repository;

  GetQuizDataFromDB(this.repository);

  Future<List<Map<String, String>>> call(String databaseId) {
    return repository.getQuizDataFromDB(databaseId);
  }
}
