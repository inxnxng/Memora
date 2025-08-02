import 'dart:convert';

import 'package:memora/constants/storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  Future<void> saveUserName(String userId, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${StorageKeys.userNameKey}$userId', name);
  }

  Future<String?> loadUserName(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('${StorageKeys.userNameKey}$userId');
  }

  Future<void> saveUserEmail(String userId, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${StorageKeys.userEmailKey}$userId', email);
  }

  Future<String?> loadUserEmail(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('${StorageKeys.userEmailKey}$userId');
  }

  Future<void> saveUserPhotoUrl(String userId, String photoUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${StorageKeys.userPhotoUrlKey}$userId', photoUrl);
  }

  Future<String?> loadUserPhotoUrl(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('${StorageKeys.userPhotoUrlKey}$userId');
  }

  Future<void> saveChatHistory(
    String taskId,
    List<Map<String, dynamic>> history,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> encodedHistory = history
        .map((msg) => '${msg['role']}|${msg['content']}|${msg['timestamp']}')
        .toList();
    await prefs.setStringList(
      '${StorageKeys.chatHistoryKey}$taskId',
      encodedHistory,
    );
  }

  Future<List<Map<String, dynamic>>> loadChatHistory(String taskId) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = '${StorageKeys.chatHistoryKey}$taskId';

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
    await prefs.setString(StorageKeys.lastTrainingResultKey, result);
  }

  Future<String?> loadLastTrainingResult() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(StorageKeys.lastTrainingResultKey);
  }

  String getAppropriateKeyName(String service) {
    if (service == "openai") {
      return StorageKeys.openAIApiKeyKey;
    } else if (service == "notion") {
      return StorageKeys.notionApiKeyKey;
    }
    return '';
  }

  String getAppropriateTimeStampName(String service) {
    if (service == "openai") {
      return StorageKeys.openAIApiKeyTimestampKey;
    } else if (service == "notion") {
      return StorageKeys.notionApiKeyTimestampKey;
    }
    return '';
  }

  Future<void> saveApiKeyWithTimestamp(String keyName, String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(getAppropriateKeyName(keyName), apiKey);
    await prefs.setString(
      getAppropriateTimeStampName(keyName),
      DateTime.now().toIso8601String(),
    );
  }

  Future<Map<String, String?>> getApiKeyWithTimestamp(String keyName) async {
    final prefs = await SharedPreferences.getInstance();

    String? apiKey = prefs.getString(getAppropriateKeyName(keyName));
    String? timeStamp = prefs.getString(getAppropriateTimeStampName(keyName));

    return {'value': apiKey, 'timestamp': timeStamp};
  }

  Future<void> deleteApiKey(String keyName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(getAppropriateKeyName(keyName));
    await prefs.remove(getAppropriateTimeStampName(keyName));
  }

  Future<void> saveUserLevel(String userId, String level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${StorageKeys.userLevelKey}$userId', level);
    await prefs.setString(
      '${StorageKeys.userLevelTimestampKey}$userId',
      DateTime.now().toIso8601String(),
    );
  }

  Future<Map<String, String?>> loadUserLevel(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final level = prefs.getString('${StorageKeys.userLevelKey}$userId');
    final timestamp = prefs.getString(
      '${StorageKeys.userLevelTimestampKey}$userId',
    );
    return {'level': level, 'timestamp': timestamp};
  }

  Future<void> saveLastTrainedDate(String taskId, DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '${StorageKeys.lastTrainedDateKey}$taskId',
      date.toIso8601String(),
    );
  }

  Future<DateTime?> loadLastTrainedDate(String taskId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? dateString = prefs.getString(
      '${StorageKeys.lastTrainedDateKey}$taskId',
    );
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
    final streakDateKey = '${StorageKeys.streakDateKey}$userId';
    final streakCountKey = '${StorageKeys.streakCountKey}$userId';

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
    return prefs.getInt('${StorageKeys.streakCountKey}$userId') ?? 0;
  }

  /// Records a study session for the given date for the heat-map.
  Future<void> recordSession(String userId, DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${StorageKeys.sessionMapKey}$userId';
    final dateString = "${date.year}-${date.month}-${date.day}";

    final sessionMap = await loadSessionMap(userId);
    sessionMap[dateString] = (sessionMap[dateString] ?? 0) + 1;

    await prefs.setString(key, json.encode(sessionMap));
  }

  /// Loads the session map for the heat-map.
  Future<Map<String, int>> loadSessionMap(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${StorageKeys.sessionMapKey}$userId';
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

  // Generic value getter
  Future<String?> getValue(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  // Generic value setter
  Future<void> saveValue(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> addStudyRecord(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final records = prefs.getStringList(StorageKeys.studyRecords) ?? [];
    final dateString = date.toIso8601String().substring(0, 10); // YYYY-MM-DD

    // Add the date string to the list
    records.add(dateString);

    // Save the updated list
    await prefs.setStringList(StorageKeys.studyRecords, records);
  }

  Future<Map<DateTime, int>> getStudyRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final records = prefs.getStringList(StorageKeys.studyRecords) ?? [];
    final Map<DateTime, int> heatmapData = {};

    for (final dateString in records) {
      final date = DateTime.parse(dateString);
      final dayOnly = DateTime(date.year, date.month, date.day);
      heatmapData[dayOnly] = (heatmapData[dayOnly] ?? 0) + 1;
    }

    return heatmapData;
  }
}
