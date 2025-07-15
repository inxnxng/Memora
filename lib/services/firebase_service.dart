import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:memora/models/task_model.dart';
import 'package:memora/models/user_model.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<void> signInAnonymously() async {
    if (currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  Future<void> saveTasks(List<Task> tasks) async {
    if (currentUser == null) return;
    final userDoc = _firestore.collection('users').doc(currentUser!.uid);
    final batch = _firestore.batch();

    for (var task in tasks) {
      batch.set(userDoc.collection('tasks').doc(task.id), {
        'title': task.title,
        'description': task.description,
        'day': task.day,
        'isCompleted': task.isCompleted,
      });
    }
    await batch.commit();
  }

  Future<List<Task>> getTasks() async {
    if (currentUser == null) return [];
    final snapshot = await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('tasks')
        .orderBy('day')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Task(
        id: doc.id,
        title: data['title'] ?? '',
        description: data['description'] ?? '',
        day: data['day'] ?? 0,
        isCompleted: data['isCompleted'] ?? false,
      );
    }).toList();
  }

  Future<void> updateTaskCompletion(String taskId, bool isCompleted) async {
    if (currentUser == null) return;
    await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('tasks')
        .doc(taskId)
        .update({'isCompleted': isCompleted});
  }

  Future<void> updateUserProfile(String name, double progress) async {
    if (currentUser == null) return;
    await _firestore.collection('users').doc(currentUser!.uid).set({
      'displayName': name,
      'progress': progress,
    }, SetOptions(merge: true));
  }

  Future<List<AppUser>> getRanking() async {
    final snapshot = await _firestore
        .collection('users')
        .orderBy('progress', descending: true)
        .limit(100)
        .get();
    return snapshot.docs
        .map((doc) => AppUser.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<AppUser?> getCurrentUser() async {
    if (currentUser == null) return null;
    final doc = await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.id, doc.data()!);
  }
}
