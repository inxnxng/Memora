import 'package:memora/domain/repositories/openai_repository.dart';
import 'package:memora/data/datasources/openai_remote_data_source.dart';
import 'package:memora/domain/repositories/openai_api_key_repository.dart';

class OpenAIRepositoryImpl implements OpenAIRepository {
  final OpenAIRemoteDataSource remoteDataSource;
  final OpenAIApiKeyRepository apiKeyRepository;

  OpenAIRepositoryImpl({
    required this.remoteDataSource,
    required this.apiKeyRepository,
  });

  @override
  Future<String> generateTrainingContent(String userPrompt) async {
    final keyData = await apiKeyRepository.getApiKeyWithTimestamp();
    final apiKey = keyData['value'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('OpenAI API key not found.');
    }
    return remoteDataSource.generateTrainingContent(userPrompt);
  }

  @override
  Future<Map<String, dynamic>> createQuizFromText(String text) async {
    final keyData = await apiKeyRepository.getApiKeyWithTimestamp();
    final apiKey = keyData['value'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('OpenAI API key not found.');
    }
    return remoteDataSource.createQuizFromText(text);
  }
}
