import 'package:memora/domain/repositories/notion_repository.dart';

class GetPageContent {
  final NotionRepository repository;

  GetPageContent(this.repository);

  Future<String> call(String pageId) {
    return repository.getPageContent(pageId);
  }
}
