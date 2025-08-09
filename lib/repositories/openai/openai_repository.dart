import 'package:memora/data/datasources/openai_remote_data_source.dart';
import 'package:memora/repositories/openai/openai_auth_repository.dart';

class OpenAIRepository {
  final OpenAIRemoteDataSource remoteDataSource;
  final OpenAIAuthRepository authRepository;

  OpenAIRepository({
    required this.remoteDataSource,
    required this.authRepository,
  });

  Future<String> _getApiKey() async {
    final keyData = await authRepository.getApiKeyWithTimestamp();
    final apiKey = keyData['value'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('OpenAI API key not found.');
    }
    return apiKey;
  }

  Stream<String> generateTrainingContentStream(
    List<Map<String, String>> messages,
  ) async* {
    final apiKey = await _getApiKey();
    yield* remoteDataSource.generateTrainingContentStream(messages, apiKey);
  }

  Future<String> generateTrainingContent(
    List<Map<String, String>> messages,
  ) async {
    final apiKey = await _getApiKey();
    return remoteDataSource.generateTrainingContent(messages, apiKey);
  }

  Future<Map<String, dynamic>> createQuizFromText(String text) async {
    final apiKey = await _getApiKey();
    return remoteDataSource.createQuizFromText(text, apiKey);
  }

  Future<bool> validateApiKey(String apiKey) {
    return remoteDataSource.validateApiKey(apiKey);
  }
}
