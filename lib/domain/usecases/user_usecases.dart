import 'package:memora/services/local_storage_service.dart';

class UserUsecases {
  final LocalStorageService localStorageService;

  UserUsecases(this.localStorageService);

  Future<String?> loadUserLevel(String userId) async {
    final data = await localStorageService.loadUserLevel(userId);
    return data['level'];
  }

  Future<Map<String, String?>> loadUserLevelWithTimestamp(String userId) {
    return localStorageService.loadUserLevel(userId);
  }

  Future<void> saveUserLevel(String userId, String level) =>
      localStorageService.saveUserLevel(userId, level);

  Future<int> getDailyGoal(String userId) async {
    final level = await loadUserLevel(userId);
    switch (level) {
      case 'expert':
        return 7;
      case 'intermediate':
        return 5;
      case 'beginner':
      default:
        return 3;
    }
  }

  Future<String> getOrCreateUserId() => localStorageService.getOrCreateUserId();

  // Streak and Session Methods
  Future<void> incrementStreak(String userId, DateTime date) =>
      localStorageService.incrementStreak(userId, date);

  Future<int> loadStreakCount(String userId) =>
      localStorageService.loadStreakCount(userId);

  Future<void> recordSession(String userId, DateTime date) =>
      localStorageService.recordSession(userId, date);

  Future<Map<String, int>> loadSessionMap(String userId) =>
      localStorageService.loadSessionMap(userId);
}
