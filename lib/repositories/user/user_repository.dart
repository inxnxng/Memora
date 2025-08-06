import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/models/proficiency_level.dart';
import 'package:memora/services/local_storage_service.dart';

class UserRepository {
  final LocalStorageService _localStorageService;
  final FirebaseFirestore _firestore;

  UserRepository(this._localStorageService, this._firestore);

  Future<void> createUser(
      String userId, String? displayName, String? email, String? photoUrl) async {
    final userRef = _firestore.collection('users').doc(userId);
    final doc = await userRef.get();

    if (!doc.exists) {
      // Document does not exist, create it with initial values
      await userRef.set({
        'displayName': displayName ?? 'Anonymous User',
        'email': email,
        'photoURL': photoUrl,
        'streakCount': 0,
        'level': ProficiencyLevel.beginner.name,
        'createdAt': FieldValue.serverTimestamp(),
      });
      // Also save to local storage
      await _localStorageService.saveUserName(userId, displayName ?? 'Anonymous User');
      if (email != null) await _localStorageService.saveUserEmail(userId, email);
      if (photoUrl != null) await _localStorageService.saveUserPhotoUrl(userId, photoUrl);
    }
  }

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
}