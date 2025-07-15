class AppUser {
  final String uid;
  final String displayName;
  final double progress;

  AppUser({
    required this.uid,
    required this.displayName,
    required this.progress,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      displayName: data['displayName'] ?? '익명',
      progress: (data['progress'] ?? 0.0).toDouble(),
    );
  }
}
