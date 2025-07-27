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

  Future<String> generateTrainingContent(String userPrompt) async {
    await _getApiKey(); // Ensures API key exists before making a call
    return remoteDataSource.generateTrainingContent(userPrompt);
  }

  Future<Map<String, dynamic>> createQuizFromText(String text) async {
    await _getApiKey(); // Ensures API key exists before making a call
    return remoteDataSource.createQuizFromText(text);
  }
}
