import 'package:memora/models/proficiency_level.dart';
import 'package:memora/services/local_storage_service.dart';

class UserRepository {
  final LocalStorageService _localStorageService;

  UserRepository(this._localStorageService);

  Future<ProficiencyLevel?> loadUserLevel(String userId) async {
    final data = await _localStorageService.loadUserLevel(userId);
    return ProficiencyLevel.fromString(data['level']);
  }

  Future<Map<String, String?>> loadUserLevelWithTimestamp(String userId) {
    return _localStorageService.loadUserLevel(userId);
  }

  Future<void> saveUserLevel(String userId, ProficiencyLevel level) =>
      _localStorageService.saveUserLevel(userId, level.name);

  Future<void> saveUserName(String userId, String name) =>
      _localStorageService.saveUserName(userId, name);

  Future<String?> loadUserName(String userId) =>
      _localStorageService.loadUserName(userId);

  Future<void> saveUserEmail(String userId, String email) =>
      _localStorageService.saveUserEmail(userId, email);

  Future<String?> loadUserEmail(String userId) =>
      _localStorageService.loadUserEmail(userId);

  Future<void> saveUserPhotoUrl(String userId, String photoUrl) =>
      _localStorageService.saveUserPhotoUrl(userId, photoUrl);

  Future<String?> loadUserPhotoUrl(String userId) =>
      _localStorageService.loadUserPhotoUrl(userId);

  // Streak and Session Methods
  Future<void> incrementStreak(String userId, DateTime date) =>
      _localStorageService.incrementStreak(userId, date);

  Future<int> loadStreakCount(String userId) =>
      _localStorageService.loadStreakCount(userId);

  Future<void> recordSession(String userId, DateTime date) =>
      _localStorageService.recordSession(userId, date);

  Future<Map<String, int>> loadSessionMap(String userId) =>
      _localStorageService.loadSessionMap(userId);
}
