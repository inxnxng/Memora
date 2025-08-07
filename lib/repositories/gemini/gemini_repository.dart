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

  Future<String> generateQuizFromText(String text) async {
    final apiKey = await _getApiKey();
    return remoteDataSource.generateQuizFromText(text, apiKey);
  }
}
