import 'dart:math';

class AppUser {
  final String uid;
  final String displayName;
  final String? email;
  final String? photoURL;
  final double progress;
  final String? geminiApiKey;
  final DateTime? geminiApiKeySetAt;

  AppUser({
    required this.uid,
    required this.displayName,
    this.email,
    this.photoURL,
    required this.progress,
    this.geminiApiKey,
    this.geminiApiKeySetAt,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      displayName: data['displayName'] ?? randomName(),
      email: data['email'],
      photoURL: data['photoURL'],
      progress: (data['progress'] ?? 0.0).toDouble(),
      geminiApiKey: data['geminiApiKey'],
      geminiApiKeySetAt: data['geminiApiKeySetAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'photoURL': photoURL,
      'progress': progress,
      'geminiApiKey': geminiApiKey,
      'geminiApiKeySetAt': geminiApiKeySetAt,
    };
  }

  AppUser copyWith({
    String? displayName,
    String? email,
    String? photoURL,
    double? progress,
    String? geminiApiKey,
    DateTime? geminiApiKeySetAt,
  }) {
    return AppUser(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoURL: photoURL ?? this.photoURL,
      progress: progress ?? this.progress,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      geminiApiKeySetAt: geminiApiKeySetAt ?? this.geminiApiKeySetAt,
    );
  }
}

String randomName() {
  final adjectives = [
    'Happy',
    'Clever',
    'Brave',
    'Sunny',
    'Wise',
    'Gentle',
    'Swift',
    'Curious',
    'Witty',
    'Eager',
    'Vivid',
    'Silent',
    'Golden',
    'Cosmic',
    'Mystic',
  ];
  final nouns = [
    'Panda',
    'Tiger',
    'Lion',
    'Eagle',
    'Dolphin',
    'Fox',
    'Wolf',
    'Bear',
    'Shark',
    'Owl',
    'Phoenix',
    'Dragon',
    'Unicorn',
    'Griffin',
    'Sphinx',
  ];
  final random = Random();
  final adjective = adjectives[random.nextInt(adjectives.length)];
  final noun = nouns[random.nextInt(nouns.length)];
  final number = random.nextInt(100);
  return '$adjective$noun$number';
}
