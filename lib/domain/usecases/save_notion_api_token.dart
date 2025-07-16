import 'package:memora/domain/repositories/notion_auth_repository.dart';

class SaveNotionApiToken {
  final NotionAuthRepository repository;

  SaveNotionApiToken(this.repository);

  Future<void> call(String apiToken) {
    return repository.saveApiToken(apiToken);
  }
}
