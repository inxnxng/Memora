import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:memora/models/proficiency_level.dart';
import 'package:memora/services/local_storage_service.dart';

class UserRepository {
  final LocalStorageService _localStorageService;
  final FirebaseFirestore _firestore;

  UserRepository(this._localStorageService, this._firestore);

  Future<void> createUser(
    String userId,
    String? displayName,
    String? email,
    String? photoUrl,
  ) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final doc = await userRef.get();

      if (!doc.exists) {
        // Document does not exist, create it with initial values
        await userRef.set({
          'displayName': displayName ?? 'Anonymous User',
          'email': email,
          'photoURL': photoUrl,
          'streakCount': 0,
          'totalSessionCount': 0,
          'rankingScore': 0,
          'level': ProficiencyLevel.beginner.name,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
        // Also save to local storage
        await _localStorageService.saveUserName(
          userId,
          displayName ?? 'Anonymous User',
        );
        if (email != null) {
          await _localStorageService.saveUserEmail(userId, email);
        }
        if (photoUrl != null) {
          await _localStorageService.saveUserPhotoUrl(userId, photoUrl);
        }
      }
    } catch (e) {
      debugPrint('Error creating user in Firestore: $e');
      // Even if Firestore fails, we should ensure local storage has the basic info if possible
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
    try {
      // Also save to Firestore to be used for ranking or other features
      await _firestore.collection('users').doc(userId).set({
        'level': level.name,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving user level to Firestore: $e');
    }
  }

  Future<void> saveUserName(String userId, String name) async {
    await _localStorageService.saveUserName(userId, name);
    try {
      await _firestore.collection('users').doc(userId).set({
        'displayName': name,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving user name to Firestore: $e');
    }
  }

  Future<String?> loadUserName(String userId) =>
      _localStorageService.loadUserName(userId);

  Future<void> saveUserEmail(String userId, String email) async {
    await _localStorageService.saveUserEmail(userId, email);
    try {
      await _firestore.collection('users').doc(userId).set({
        'email': email,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving user email to Firestore: $e');
    }
  }

  Future<String?> loadUserEmail(String userId) =>
      _localStorageService.loadUserEmail(userId);

  Future<void> saveUserPhotoUrl(String userId, String photoUrl) async {
    await _localStorageService.saveUserPhotoUrl(userId, photoUrl);
    try {
      await _firestore.collection('users').doc(userId).set({
        'photoURL': photoUrl,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving user photo URL to Firestore: $e');
    }
  }

  Future<String?> loadUserPhotoUrl(String userId) =>
      _localStorageService.loadUserPhotoUrl(userId);

  Future<void> savePreferredAi(String userId, String preferredAi) async {
    await _localStorageService.savePreferredAi(userId, preferredAi);
    try {
      await _firestore.collection('users').doc(userId).set({
        'preferredAi': preferredAi,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving preferred AI to Firestore: $e');
    }
  }

  Future<String?> loadPreferredAi(String userId) {
    return _localStorageService.loadPreferredAi(userId);
  }

  // Streak and Session Methods
  Future<void> incrementStreak(String userId, DateTime date) async {
    await _localStorageService.incrementStreak(userId, date);
    final newStreakCount = await _localStorageService.loadStreakCount(userId);
    try {
      await _firestore.collection('users').doc(userId).set({
        'streakCount': newStreakCount,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating streak count in Firestore: $e');
    }
  }

  Future<int> loadStreakCount(String userId) =>
      _localStorageService.loadStreakCount(userId);

  Future<void> recordSession(String userId, DateTime date) =>
      _localStorageService.recordSession(userId, date);

  Future<Map<String, int>> loadSessionMap(String userId) =>
      _localStorageService.loadSessionMap(userId);

  /// 학습 횟수 1회당 10pt, 스트릭 1일당 20pt로 랭킹 점수 계산 후 Firestore에 반영
  Future<void> updateRankingScore(
    String userId,
    int totalSessionCount,
    int streakCount,
  ) async {
    final rankingScore = totalSessionCount * 10 + streakCount * 20;
    try {
      await _firestore.collection('users').doc(userId).set({
        'totalSessionCount': totalSessionCount,
        'rankingScore': rankingScore,
        'streakCount': streakCount,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating ranking score in Firestore: $e');
    }
  }

  /// Firestore에 rankingScore가 없으면 0으로 초기화 (기존 유저 호환)
  Future<void> ensureRankingScoreExists(String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final doc = await userRef.get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && !data.containsKey('rankingScore')) {
          await userRef.set({
            'totalSessionCount': data['totalSessionCount'] ?? 0,
            'rankingScore': data['rankingScore'] ?? 0,
            'streakCount': data['streakCount'] ?? 0,
          }, SetOptions(merge: true));
        }
      }
    } catch (e) {
      debugPrint('Error ensuring ranking score exists in Firestore: $e');
    }
  }

  Future<void> updateUserLastLogin(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'lastLoginAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating last login in Firestore: $e');
    }
  }

  Future<void> updateGeminiApiKey(String userId, String apiKey) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'geminiApiKey': apiKey,
        'geminiApiKeySetAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating Gemini API key in Firestore: $e');
    }
  }

  Future<void> saveEncryptedApiKeys(
    String uid,
    Map<String, String> encryptedKeys,
  ) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'encryptedApiKeys': encryptedKeys,
        'apiKeysUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving encrypted API keys to Firestore: $e');
    }
  }

  Future<Map<String, String>> loadEncryptedApiKeys(String uid) async {
    try {
      final snapshot = await _firestore.collection('users').doc(uid).get();
      final data = snapshot.data();
      if (data == null || !data.containsKey('encryptedApiKeys')) {
        return {};
      }
      return Map<String, String>.from(data['encryptedApiKeys']);
    } catch (e) {
      debugPrint('Error loading encrypted API keys from Firestore: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      debugPrint('Error getting user data from Firestore: $e');
      return null;
    }
  }

  Future<void> ensureStreakCountExists(String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final doc = await userRef.get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          final updates = <String, dynamic>{};
          if (!data.containsKey('streakCount')) updates['streakCount'] = 0;
          if (!data.containsKey('rankingScore')) {
            updates['totalSessionCount'] = data['totalSessionCount'] ?? 0;
            updates['rankingScore'] = 0;
          }
          if (updates.isNotEmpty) {
            await userRef.set(updates, SetOptions(merge: true));
          }
        }
      }
    } catch (e) {
      debugPrint('Error ensuring streak count exists in Firestore: $e');
    }
  }
}
