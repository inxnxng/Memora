import 'package:memora/domain/repositories/notion_repository.dart';

class SearchNotionDatabases {
  final NotionRepository repository;

  SearchNotionDatabases(this.repository);

  Future<List<dynamic>> call({String? query}) {
    return repository.searchDatabases(query: query);
  }
}
