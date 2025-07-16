import 'package:memora/domain/repositories/notion_repository.dart';

class GetRoadmapTasksFromDB {
  final NotionRepository repository;

  GetRoadmapTasksFromDB(this.repository);

  Future<List<dynamic>> call(String databaseId) {
    return repository.getRoadmapTasksFromDB(databaseId);
  }
}
