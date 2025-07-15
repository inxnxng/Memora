import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _chatHistoryKey = 'chat_history_'; // Suffix with task ID
  static const String _lastTrainingResultKey = 'last_training_result';

  Future<void> saveChatHistory(
    String taskId,
    List<Map<String, String>> history,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedHistory = history
        .map((msg) => '${msg['role']}|${msg['content']}')
        .join('\n');
    await prefs.setString('$_chatHistoryKey$taskId', encodedHistory);
  }

  Future<List<Map<String, String>>> loadChatHistory(String taskId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedHistory = prefs.getString('$_chatHistoryKey$taskId');
    if (encodedHistory == null || encodedHistory.isEmpty) {
      return [];
    }
    return encodedHistory.split('\n').map((line) {
      final parts = line.split('|');
      return {'role': parts[0], 'content': parts.sublist(1).join('|')};
    }).toList();
  } // For simplicity, storing last result as a string. Can be expanded to JSON.

  Future<void> saveLastTrainingResult(String result) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastTrainingResultKey, result);
  }

  Future<String?> loadLastTrainingResult() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastTrainingResultKey);
  }

  static const String _lastTrainedDateKey =
      'last_trained_date_'; // Suffix with task ID

  Future<void> saveLastTrainedDate(String taskId, DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_lastTrainedDateKey$taskId',
      date.toIso8601String(),
    );
  }

  Future<DateTime?> loadLastTrainedDate(String taskId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? dateString = prefs.getString('$_lastTrainedDateKey$taskId');
    if (dateString == null) {
      return null;
    }
    return DateTime.tryParse(dateString);
  }
}
