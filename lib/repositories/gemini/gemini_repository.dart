import 'package:memora/data/datasources/gemini_remote_data_source.dart';
import 'package:memora/repositories/gemini/gemini_auth_repository.dart';

class GeminiRepository {
  final GeminiRemoteDataSource remoteDataSource;
  final GeminiAuthRepository authRepository;

  GeminiRepository({
    required this.remoteDataSource,
    required this.authRepository,
  });

  Future<String> _getApiKey() async {
    final keyData = await authRepository.getApiKeyWithTimestamp();
    final apiKey = keyData['value'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Gemini API key not found.');
    }
    return apiKey;
  }

  Stream<String> generateQuizFromText(
    List<Map<String, String>> messages,
  ) async* {
    final apiKey = await _getApiKey();
    yield* remoteDataSource.generateQuizFromText(messages, apiKey);
  }

  Future<String> createQuizFromText(String text) async {
    final apiKey = await _getApiKey();
    return remoteDataSource.createQuizFromText(text, apiKey);
  }

  Future<bool> validateApiKey(String apiKey) {
    return remoteDataSource.validateApiKey(apiKey);
  }
}
