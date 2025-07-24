import 'package:memora/data/datasources/openai_remote_data_source.dart';
import 'package:memora/repositories/openai_api_key_repository.dart';

class OpenAIRepository {
  final OpenAIRemoteDataSource remoteDataSource;
  final OpenAIApiKeyRepository apiKeyRepository;

  OpenAIRepository({
    required this.remoteDataSource,
    required this.apiKeyRepository,
  });

  Future<String> generateTrainingContent(String userPrompt) async {
    final keyData = await apiKeyRepository.getApiKeyWithTimestamp();
    final apiKey = keyData['value'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('OpenAI API key not found.');
    }
    return remoteDataSource.generateTrainingContent(userPrompt);
  }

  Future<Map<String, dynamic>> createQuizFromText(String text) async {
    final keyData = await apiKeyRepository.getApiKeyWithTimestamp();
    final apiKey = keyData['value'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('OpenAI API key not found.');
    }
    return remoteDataSource.createQuizFromText(text);
  }
}
