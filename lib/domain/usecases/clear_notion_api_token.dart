import 'package:memora/domain/repositories/notion_auth_repository.dart';

class ClearNotionApiToken {
  final NotionAuthRepository repository;

  ClearNotionApiToken(this.repository);

  Future<void> call() {
    return repository.clearApiToken();
  }
}
