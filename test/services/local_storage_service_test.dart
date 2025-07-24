import 'package:flutter_test/flutter_test.dart';
import 'package:memora/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LocalStorageService', () {
    late LocalStorageService localStorageService;
    const userId = 'test_user';
    // Use a fixed date to make tests deterministic and avoid issues with `DateTime.now()`
    final today = DateTime(2025, 7, 25);
    final yesterday = today.subtract(const Duration(days: 1));
    final twoDaysAgo = today.subtract(const Duration(days: 2));

    setUp(() {
      // Set up mock initial values for SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      localStorageService = LocalStorageService();
    });

    group('Streak Tracking', () {
      test('incrementStreak should initialize streak to 1 for the first time',
          () async {
        await localStorageService.incrementStreak(userId, today);
        final streak = await localStorageService.loadStreakCount(userId);
        expect(streak, 1);
      });

      test(
          'incrementStreak should increment streak if the last session was yesterday',
          () async {
        // Simulate that the user studied yesterday
        await localStorageService.incrementStreak(userId, yesterday);
        var streak = await localStorageService.loadStreakCount(userId);
        expect(streak, 1);

        // User studies today
        await localStorageService.incrementStreak(userId, today);
        streak = await localStorageService.loadStreakCount(userId);
        expect(streak, 2);
      });

      test(
          'incrementStreak should not increment streak if the last session was today',
          () async {
        await localStorageService.incrementStreak(userId, today);
        var streak = await localStorageService.loadStreakCount(userId);
        expect(streak, 1);

        // User studies again today
        await localStorageService.incrementStreak(userId, today);
        streak = await localStorageService.loadStreakCount(userId);
        expect(streak, 1);
      });

      test(
          'incrementStreak should reset streak to 1 if the last session was before yesterday',
          () async {
        // Simulate that the user studied two days ago
        await localStorageService.incrementStreak(userId, twoDaysAgo);
        var streak = await localStorageService.loadStreakCount(userId);
        expect(streak, 1);

        // User studies today, streak should reset
        await localStorageService.incrementStreak(userId, today);
        streak = await localStorageService.loadStreakCount(userId);
        expect(streak, 1);
      });

      test('loadStreakCount should return 0 if no streak is saved', () async {
        final streak = await localStorageService.loadStreakCount(userId);
        expect(streak, 0);
      });
    });

    group('Heat-map Session Recording', () {
      test('recordSession should add a new entry for a new date', () async {
        await localStorageService.recordSession(userId, today);

        final sessionMap = await localStorageService.loadSessionMap(userId);
        final dateString = "${today.year}-${today.month}-${today.day}";

        expect(sessionMap, isA<Map<String, int>>());
        expect(sessionMap.length, 1);
        expect(sessionMap[dateString], 1);
      });

      test('recordSession should increment the count for an existing date',
          () async {
        final dateString = "${today.year}-${today.month}-${today.day}";

        // Record first session
        await localStorageService.recordSession(userId, today);
        var sessionMap = await localStorageService.loadSessionMap(userId);
        expect(sessionMap[dateString], 1);

        // Record second session on the same day
        await localStorageService.recordSession(userId, today);
        sessionMap = await localStorageService.loadSessionMap(userId);
        expect(sessionMap[dateString], 2);
      });

      test('recordSession should handle multiple dates correctly', () async {
        final todayString = "${today.year}-${today.month}-${today.day}";
        final yesterdayString =
            "${yesterday.year}-${yesterday.month}-${yesterday.day}";

        await localStorageService.recordSession(userId, yesterday);
        await localStorageService.recordSession(userId, today);
        await localStorageService.recordSession(userId, today);

        final sessionMap = await localStorageService.loadSessionMap(userId);
        expect(sessionMap.length, 2);
        expect(sessionMap[yesterdayString], 1);
        expect(sessionMap[todayString], 2);
      });

      test('loadSessionMap should return an empty map if no data is saved',
          () async {
        final sessionMap = await localStorageService.loadSessionMap(userId);
        expect(sessionMap, isA<Map<String, int>>());
        expect(sessionMap.isEmpty, isTrue);
      });
    });
  });
}
