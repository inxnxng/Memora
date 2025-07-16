abstract class OpenAIRepository {
  Future<String> generateTrainingContent(String userPrompt);
  Future<Map<String, dynamic>> createQuizFromText(String text);
}
