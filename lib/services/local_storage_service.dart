import 'dart:async';
import 'dart:convert';

import 'package:memora/constants/storage_keys.dart';
import 'package:memora/models/chat_message.dart';
import 'package:memora/models/chat_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  final Map<String, StreamController<List<ChatMessage>>>
  _chatHistoryControllers = {};

  // Private constructor
  LocalStorageService._internal();

  // Singleton instance
  static final LocalStorageService _instance = LocalStorageService._internal();

  // Factory constructor to return the singleton instance
  factory LocalStorageService() {
    return _instance;
  }

  // Method to dispose of all controllers when the app closes or is no longer needed
  void dispose() {
    _chatHistoryControllers.forEach((key, controller) {
      controller.close();
    });
    _chatHistoryControllers.clear();
  }

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

  Future<void> savePreferredAi(String userId, String preferredAi) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${StorageKeys.preferredAiKey}$userId', preferredAi);
  }

  Future<String?> loadPreferredAi(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('${StorageKeys.preferredAiKey}$userId');
  }

  /// Saves a list of ChatMessage objects to local storage.
  Future<void> saveChatHistory(
    String chatId,
    List<ChatMessage> messages,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${StorageKeys.chatHistoryKey}$chatId';
    final List<String> encodedHistory = messages
        .map((msg) => json.encode(msg.toLocalMap()))
        .toList();
    await prefs.setStringList(key, encodedHistory);
    // Add the updated messages to the stream
    if (_chatHistoryControllers.containsKey(chatId)) {
      _chatHistoryControllers[chatId]!.add(messages);
    }
  }

  Future<void> saveChatSession(
    String chatId,
    String pageTitle,
    DateTime lastMessageTimestamp,
    String? databaseName,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${StorageKeys.chatSessionKey}$chatId';
    final chatSession = ChatSession(
      chatId: chatId,
      pageTitle: pageTitle,
      lastMessageTimestamp: lastMessageTimestamp,
      databaseName: databaseName ?? '',
    );
    await prefs.setString(key, json.encode(chatSession.toMap()));
  }

  Future<bool> chatSessionExists(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${StorageKeys.chatSessionKey}$chatId';
    return prefs.containsKey(key);
  }

  Stream<List<ChatMessage>> loadChatHistory(String chatId) async* {
    // Ensure a controller exists for this chatId
    if (!_chatHistoryControllers.containsKey(chatId)) {
      _chatHistoryControllers[chatId] =
          StreamController<List<ChatMessage>>.broadcast();
    }

    // Emit the current history from SharedPreferences first
    final prefs = await SharedPreferences.getInstance();
    final key = '${StorageKeys.chatHistoryKey}$chatId';
    final List<String>? encodedHistoryList = prefs.getStringList(key);
    List<ChatMessage> initialMessages = [];
    if (encodedHistoryList != null && encodedHistoryList.isNotEmpty) {
      try {
        initialMessages = encodedHistoryList
            .map((line) => ChatMessage.fromLocalMap(json.decode(line)))
            .toList();
      } catch (e) {
        // Handle decoding errors, return empty list
      }
    }
    yield initialMessages;

    // Yield subsequent updates from the controller
    yield* _chatHistoryControllers[chatId]!.stream;
  }

  Future<void> deleteChatHistory(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${StorageKeys.chatHistoryKey}$chatId';
    await prefs.remove(key);
  }

  Future<void> deleteChatSession(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${StorageKeys.chatSessionKey}$chatId';
    await prefs.remove(key);
  }

  Future<List<String>> getAllChatHistoryKeys() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs
        .getKeys()
        .where((key) => key.startsWith(StorageKeys.chatHistoryKey))
        .toList();
  }

  Future<List<ChatSession>> getAllChatSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs
        .getKeys()
        .where((key) => key.startsWith(StorageKeys.chatSessionKey))
        .toList();

    final List<ChatSession> sessions = [];
    for (final key in allKeys) {
      final jsonString = prefs.getString(key);
      if (jsonString != null) {
        sessions.add(ChatSession.fromMap(json.decode(jsonString)));
      }
    }
    return sessions;
  }

  String getOriginalKey(String storageKey) {
    return storageKey.replaceFirst(StorageKeys.chatHistoryKey, '');
  }

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
    } else if (service == "gemini") {
      return StorageKeys.geminiApiKeyKey;
    }
    return '';
  }

  String getAppropriateTimeStampName(String service) {
    if (service == "openai") {
      return StorageKeys.openAIApiKeyTimestampKey;
    } else if (service == "notion") {
      return StorageKeys.notionApiKeyTimestampKey;
    } else if (service == "gemini") {
      return StorageKeys.geminiApiKeyTimestampKey;
    }
    return '';
  }

  String getAppropriateValidStatusKeyName(String service) {
    if (service == "openai") {
      return StorageKeys.openAIApiKeyValidStatusKey;
    } else if (service == "notion") {
      return StorageKeys.notionApiKeyValidStatusKey;
    } else if (service == "gemini") {
      return StorageKeys.geminiApiKeyValidStatusKey;
    }
    return '';
  }

  Future<void> saveApiKeyValidStatus(String keyName, bool isValid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(getAppropriateValidStatusKeyName(keyName), isValid);
  }

  Future<bool?> getApiKeyValidStatus(String keyName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(getAppropriateValidStatusKeyName(keyName));
  }

  Future<void> deleteApiKeyValidStatus(String keyName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(getAppropriateValidStatusKeyName(keyName));
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
    await deleteApiKeyValidStatus(keyName);
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
      final today = DateTime(date.year, date.month, date.day);
      final lastStudyDay = DateTime(
        lastDate.year,
        lastDate.month,
        lastDate.day,
      );
      final difference = today.difference(lastStudyDay).inDays;

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

  Future<void> addStudyRecord(
    DateTime date, {
    String? databaseName,
    required String title,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final records = prefs.getStringList(StorageKeys.studyRecords) ?? [];
    final record = {
      'date': date.toIso8601String().substring(0, 10), // YYYY-MM-DD
      'databaseName': databaseName,
      'title': title,
    };
    records.add(json.encode(record));
    await prefs.setStringList(StorageKeys.studyRecords, records);
  }

  Future<Map<DateTime, List<Map<String, dynamic>>>> getStudyRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final records = prefs.getStringList(StorageKeys.studyRecords) ?? [];
    final Map<DateTime, List<Map<String, dynamic>>> heatmapData = {};

    for (final recordString in records) {
      try {
        final record = json.decode(recordString);
        // Handle old format (just a date string)
        if (record is String) {
          final date = DateTime.parse(record);
          final dayOnly = DateTime(date.year, date.month, date.day);
          heatmapData.putIfAbsent(dayOnly, () => []);
          heatmapData[dayOnly]!.add({'databaseName': '', 'title': '기록 없음'});
        } else if (record is Map<String, dynamic>) {
          final date = DateTime.parse(record['date']);
          final dayOnly = DateTime(date.year, date.month, date.day);
          heatmapData.putIfAbsent(dayOnly, () => []);
          heatmapData[dayOnly]!.add({
            'databaseName': record['databaseName'] ?? '',
            'title': record['title'] ?? '',
          });
        }
      } catch (e) {
        // Could be an old string format, try parsing it as a date
        try {
          final date = DateTime.parse(recordString);
          final dayOnly = DateTime(date.year, date.month, date.day);
          heatmapData.putIfAbsent(dayOnly, () => []);
          heatmapData[dayOnly]!.add({'databaseName': '', 'title': '기록 없음'});
        } catch (e2) {
          // Ignore malformed records
        }
      }
    }
    return heatmapData;
  }
}
