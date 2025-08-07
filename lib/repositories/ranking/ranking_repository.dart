import 'package:cloud_firestore/cloud_firestore.dart';

class RankingRepository {
  final FirebaseFirestore _firestore;

  RankingRepository(this._firestore);

  /// Fetches the user's rank based on their streak count.
  /// Returns the rank (1-based) or -1 if not found or an error occurs.
  Future<int> getUserRank(String userId) async {
    try {
      // This approach can be inefficient and costly for large user bases.
      // Consider using a server-side solution (e.g., Cloud Functions) for ranking in production.
      final querySnapshot = await _firestore
          .collection('users')
          .orderBy('streakCount', descending: true)
          .get();

      final userDocs = querySnapshot.docs;
      final userIndex = userDocs.indexWhere((doc) => doc.id == userId);

      return userIndex != -1 ? userIndex + 1 : -1;
    } catch (e) {
      // It's better to log the error for debugging purposes.
      // It's better to log the error for debugging purposes.'Error getting user rank: $e');
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
      });
    } catch (e) {
      // It's better to log the error for debugging purposes.'Error getting top rankings: $e');
      return Stream.value([]);
    }
  }
}
