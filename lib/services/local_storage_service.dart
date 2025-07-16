import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _chatHistoryKey = 'chat_history_'; // Suffix with task ID
  static const String _lastTrainingResultKey = 'last_training_result';
  static const String _openAIApiKeyKey = 'openai_api_key';
  static const String _openAIApiKeyTimestampKey = 'openai_api_key_timestamp';

  Future<void> saveChatHistory(
    String taskId,
    List<Map<String, dynamic>> history,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> encodedHistory = history
        .map((msg) => '${msg['role']}|${msg['content']}|${msg['timestamp']}')
        .toList();
    await prefs.setStringList('$_chatHistoryKey$taskId', encodedHistory);
  }

  Future<List<Map<String, dynamic>>> loadChatHistory(String taskId) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = '$_chatHistoryKey$taskId';

    // 1. Try to load as a single String (old format)
    final String? encodedHistoryString = prefs.getString(key);
    if (encodedHistoryString != null && encodedHistoryString.isNotEmpty) {
      final oldHistory = encodedHistoryString.split('\n').map((line) {
        final parts = line.split('|');
        return {
          'role': parts[0],
          'content': parts.sublist(1).join('|'),
          'timestamp': DateTime.now()
              .toIso8601String(), // Assign current timestamp for old data
        };
      }).toList();
      // Migrate the data to the new List<String> format
      await saveChatHistory(taskId, oldHistory);
      await prefs.remove(key); // Remove the old String entry
      return oldHistory;
    }

    // 2. If not found as a String, try to load as a List<String> (new format)
    final List<String>? encodedHistoryList = prefs.getStringList(key);
    if (encodedHistoryList != null && encodedHistoryList.isNotEmpty) {
      return encodedHistoryList.map((line) {
        final parts = line.split('|');
        return {'role': parts[0], 'content': parts[1], 'timestamp': parts[2]};
      }).toList();
    }

    return [];
  } // For simplicity, storing last result as a string. Can be expanded to JSON.

  Future<void> saveLastTrainingResult(String result) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastTrainingResultKey, result);
  }

  Future<String?> loadLastTrainingResult() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastTrainingResultKey);
  }

  Future<void> saveApiKeyWithTimestamp(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_openAIApiKeyKey, apiKey);
    await prefs.setString(
      _openAIApiKeyTimestampKey,
      DateTime.now().toIso8601String(),
    );
  }

  Future<Map<String, String?>> getApiKeyWithTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString(_openAIApiKeyKey);
    final timestamp = prefs.getString(_openAIApiKeyTimestampKey);
    return {'value': apiKey, 'timestamp': timestamp};
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
