import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class RankingRepository {
  final FirebaseFirestore _firestore;

  RankingRepository(this._firestore);

  /// Fetches the user's rank based on their streak count.
  /// Returns the rank (1-based) or -1 if not found or an error occurs.
  Future<int> getUserRank(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .orderBy('streakCount', descending: true)
          .get();

      final userDocs = querySnapshot.docs;
      final userIndex = userDocs.indexWhere((doc) => doc.id == userId);

      return userIndex != -1 ? userIndex + 1 : -1;
    } catch (e) {
      // Return -1 if there's a permission error (which happens with user-only read rules)
      debugPrint('Error getting user rank: $e');
      return -1;
    }
  }

  Stream<List<Map<String, dynamic>>> getTopRankings({int limit = 100}) {
    try {
      return _firestore
          .collection('users')
          .orderBy('streakCount', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              return {'id': doc.id, ...doc.data()};
            }).toList();
          })
          .handleError((error) {
            debugPrint('Error in getTopRankings stream: $error');
            return <Map<String, dynamic>>[];
          });
    } catch (e) {
      debugPrint('Error setting up top rankings stream: $e');
      return Stream.value([]);
    }
  }
}
