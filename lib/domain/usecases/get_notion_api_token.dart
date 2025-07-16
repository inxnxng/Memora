import 'package:memora/domain/repositories/notion_auth_repository.dart';

class GetNotionApiToken {
  final NotionAuthRepository repository;

  GetNotionApiToken(this.repository);

  Future<Map<String, String?>> call() {
    return repository.getApiTokenWithTimestamp();
  }
}
