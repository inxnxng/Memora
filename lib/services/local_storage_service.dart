import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class LocalStorageService {
  static const String _chatHistoryKey = 'chat_history_'; // Suffix with task ID
  static const String _lastTrainingResultKey = 'last_training_result';
  static const String _openAIApiKeyKey = 'openai_api_key';
  static const String _openAIApiKeyTimestampKey = 'openai_api_key_timestamp';
  static const String _lastTrainedDateKey =
      'last_trained_date_'; // Suffix with task ID
  static const String _userLevelKey = 'user_level_'; // Suffix with user ID
  static const String _userLevelTimestampKey =
      'user_level_timestamp_'; // Suffix with user ID
  static const String _streakCountKey = 'streak_count_'; // Suffix with user ID
  static const String _streakDateKey = 'streak_date_'; // Suffix with user ID
  static const String _sessionMapKey = 'session_map_'; // Suffix with user ID
  static const String _userIdKey = 'memora_user_id';

  /// Gets the stored user ID, or creates and stores a new one if none exists.
  Future<String> getOrCreateUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString(_userIdKey);
    if (userId == null) {
      userId = const Uuid().v4();
      await prefs.setString(_userIdKey, userId);
    }
    return userId;
  }

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

  Future<void> saveUserLevel(String userId, String level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_userLevelKey$userId', level);
    await prefs.setString(
      '$_userLevelTimestampKey$userId',
      DateTime.now().toIso8601String(),
    );
  }

  Future<Map<String, String?>> loadUserLevel(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final level = prefs.getString('$_userLevelKey$userId');
    final timestamp = prefs.getString('$_userLevelTimestampKey$userId');
    return {'level': level, 'timestamp': timestamp};
  }

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

  /// Increments the user's study streak.
  /// If the last session was yesterday, the streak is incremented.
  /// Otherwise, it's reset to 1.
  Future<void> incrementStreak(String userId, DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final streakDateKey = '$_streakDateKey$userId';
    final streakCountKey = '$_streakCountKey$userId';

    final lastDateString = prefs.getString(streakDateKey);
    int currentStreak = prefs.getInt(streakCountKey) ?? 0;

    if (lastDateString != null) {
      final lastDate = DateTime.parse(lastDateString);
      final difference = date.difference(lastDate).inDays;

      if (difference == 1) {
        currentStreak++;
      } else if (difference > 1) {
        currentStreak = 1; // Reset streak
      }
      // if difference is 0, do nothing.
    } else {
      currentStreak = 1; // First session
    }

    await prefs.setInt(streakCountKey, currentStreak);
    await prefs.setString(streakDateKey, date.toIso8601String());
  }

  /// Loads the user's current streak count.
  Future<int> loadStreakCount(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_streakCountKey$userId') ?? 0;
  }

  /// Records a study session for the given date for the heat-map.
  Future<void> recordSession(String userId, DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_sessionMapKey$userId';
    final dateString = "${date.year}-${date.month}-${date.day}";

    final sessionMap = await loadSessionMap(userId);
    sessionMap[dateString] = (sessionMap[dateString] ?? 0) + 1;

    await prefs.setString(key, json.encode(sessionMap));
  }

  /// Loads the session map for the heat-map.
  Future<Map<String, int>> loadSessionMap(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_sessionMapKey$userId';
    final String? jsonString = prefs.getString(key);

    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        // Ensure the decoded map is of the correct type
        final decoded = json.decode(jsonString) as Map<String, dynamic>;
        return decoded.map((key, value) => MapEntry(key, value as int));
      } catch (e) {
        // If decoding fails, return an empty map
        return {};
      }
    }
    return {};
  }
}
