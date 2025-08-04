import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/models/proficiency_level.dart';
import 'package:memora/services/local_storage_service.dart';

class UserRepository {
  final LocalStorageService _localStorageService;
  final FirebaseFirestore _firestore;

  UserRepository(this._localStorageService, this._firestore);

  Future<ProficiencyLevel?> loadUserLevel(String userId) async {
    final data = await _localStorageService.loadUserLevel(userId);
    return ProficiencyLevel.fromString(data['level']);
  }

  Future<Map<String, String?>> loadUserLevelWithTimestamp(String userId) {
    return _localStorageService.loadUserLevel(userId);
  }

  Future<void> saveUserLevel(String userId, ProficiencyLevel level) async {
    await _localStorageService.saveUserLevel(userId, level.name);
    // Also save to Firestore to be used for ranking or other features
    await _firestore.collection('users').doc(userId).set({
      'level': level.name,
    }, SetOptions(merge: true));
  }

  Future<void> saveUserName(String userId, String name) async {
    await _localStorageService.saveUserName(userId, name);
    await _firestore.collection('users').doc(userId).set({
      'displayName': name,
    }, SetOptions(merge: true));
  }

  Future<String?> loadUserName(String userId) =>
      _localStorageService.loadUserName(userId);

  Future<void> saveUserEmail(String userId, String email) async {
    await _localStorageService.saveUserEmail(userId, email);
    await _firestore.collection('users').doc(userId).set({
      'email': email,
    }, SetOptions(merge: true));
  }

  Future<String?> loadUserEmail(String userId) =>
      _localStorageService.loadUserEmail(userId);

  Future<void> saveUserPhotoUrl(String userId, String photoUrl) async {
    await _localStorageService.saveUserPhotoUrl(userId, photoUrl);
    await _firestore.collection('users').doc(userId).set({
      'photoURL': photoUrl,
    }, SetOptions(merge: true));
  }

  Future<String?> loadUserPhotoUrl(String userId) =>
      _localStorageService.loadUserPhotoUrl(userId);

  // Streak and Session Methods
  Future<void> incrementStreak(String userId, DateTime date) async {
    await _localStorageService.incrementStreak(userId, date);
    final newStreakCount = await _localStorageService.loadStreakCount(userId);
    await _firestore.collection('users').doc(userId).set({
      'streakCount': newStreakCount,
    }, SetOptions(merge: true));
  }

  Future<int> loadStreakCount(String userId) =>
      _localStorageService.loadStreakCount(userId);

  Future<void> recordSession(String userId, DateTime date) =>
      _localStorageService.recordSession(userId, date);

  Future<Map<String, int>> loadSessionMap(String userId) =>
      _localStorageService.loadSessionMap(userId);

  /// Fetches the user's rank based on their streak count.
  Future<int> getUserRank(String userId) async {
    try {
      // Get all users sorted by streakCount in descending order
      final querySnapshot = await _firestore
          .collection('users')
          .orderBy('streakCount', descending: true)
          .get();

      // Find the index (rank) of the current user
      final userDocs = querySnapshot.docs;
      for (int i = 0; i < userDocs.length; i++) {
        if (userDocs[i].id == userId) {
          return i + 1; // Rank is 1-based
        }
      }
      return -1; // User not found in rankings
    } catch (e) {
      // Handle potential errors, e.g., permissions
      return -1;
    }
  }

  /// Fetches the top rankings.
  Future<List<Map<String, dynamic>>> getTopRankings({int limit = 100}) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .orderBy('streakCount', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      return [];
    }
  }
}
