import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserFirestoreRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DocumentReference<Map<String, dynamic>>? get _userDocRef {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _firestore.collection('users').doc(user.uid);
  }

  Future<void> upsertUserData(Map<String, dynamic> data) async {
    final docRef = _userDocRef;
    if (docRef == null) throw Exception('User not logged in');
    await docRef.set(data, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final docRef = _userDocRef;
    if (docRef == null) throw Exception('User not logged in');
    final snapshot = await docRef.get();
    return snapshot.data();
  }

  Future<void> updateField(String key, dynamic value) async {
    final docRef = _userDocRef;
    if (docRef == null) throw Exception('User not logged in');
    await docRef.update({key: value});
  }

  Future<void> deleteField(String key) async {
    final docRef = _userDocRef;
    if (docRef == null) throw Exception('User not logged in');
    await docRef.update({key: FieldValue.delete()});
  }
}
