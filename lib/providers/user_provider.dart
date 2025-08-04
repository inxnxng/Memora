import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:memora/models/proficiency_level.dart';
import 'package:memora/repositories/user/user_repository.dart';

class UserProvider with ChangeNotifier {
  final UserRepository _userRepository;

  ProficiencyLevel? _userLevel;
  String? _displayName;
  String? _email;
  String? _photoURL;
  String? _levelTimestamp;
  int _streakCount = 0;
  Map<String, int> _sessionMap = {};
  int? _userRank; // User's rank
  bool _isLoading = true; // Start with loading true
  String? _userId;

  ProficiencyLevel? get userLevel => _userLevel;
  String? get displayName => _displayName;
  String? get email => _email;
  String? get photoURL => _photoURL;
  String? get levelTimestamp => _levelTimestamp;
  int get streakCount => _streakCount;
  Map<String, int> get sessionMap => _sessionMap;
  int? get userRank => _userRank;
  bool get isLoading => _isLoading;
  String? get userId => _userId; // Make it nullable

  bool get isProfileComplete => _userLevel != null;

  UserProvider({required UserRepository userRepository})
    : _userRepository = userRepository {
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _userId = user.uid;
        _syncFirebaseAuthUser(user);
        loadUserProfile(); // Load data for the new user
      } else {
        // User is logged out, reset state
        _userId = null;
        _userLevel = null;
        _displayName = null;
        _email = null;
        _photoURL = null;
        _levelTimestamp = null;
        _streakCount = 0;
        _sessionMap = {};
        _userRank = null;
        _isLoading = false;
        Future.microtask(() => notifyListeners());
      }
    });
  }

  Future<void> _syncFirebaseAuthUser(User user) async {
    _displayName = user.displayName;
    _email = user.email;
    _photoURL = user.photoURL;

    if (user.displayName != null) {
      await _userRepository.saveUserName(user.uid, user.displayName!);
    }
    if (user.email != null) {
      await _userRepository.saveUserEmail(user.uid, user.email!);
    }
    if (user.photoURL != null) {
      await _userRepository.saveUserPhotoUrl(user.uid, user.photoURL!);
    }
  }

  Future<void> loadUserProfile() async {
    if (_userId == null) {
      _isLoading = false;
      Future.microtask(() => notifyListeners());
      return;
    }

    _isLoading = true;
    Future.microtask(() => notifyListeners());

    try {
      // Fetch all user data in parallel, with individual error handling.
      await Future.wait([
        _userRepository
            .loadUserLevelWithTimestamp(_userId!)
            .then((data) {
              _userLevel = ProficiencyLevel.fromString(data['level']);
              _levelTimestamp = data['timestamp'];
            })
            .catchError((_) {
              _userLevel = null;
              _levelTimestamp = null;
            }),
        _userRepository
            .loadUserName(_userId!)
            .then((name) => _displayName = name)
            .catchError((_) => _displayName = null),
        _userRepository
            .loadUserEmail(_userId!)
            .then((email) => _email = email)
            .catchError((_) => _email = null),
        _userRepository
            .loadUserPhotoUrl(_userId!)
            .then((photoUrl) => _photoURL = photoUrl)
            .catchError((_) => _photoURL = null),
      ]);
    } catch (e) {
      // This will catch any other unexpected errors during the process.
      if (kDebugMode) {
        print("An unexpected error occurred while loading user profile: $e");
      }
    } finally {
      _isLoading = false;
      Future.microtask(() => notifyListeners());
    }
  }

  Future<void> saveUserLevel(ProficiencyLevel level) async {
    if (_userId == null) return;
    await _userRepository.saveUserLevel(_userId!, level);
    await loadUserProfile();
  }

  Future<void> saveUserName(String name) async {
    if (_userId == null) return;
    await _userRepository.saveUserName(_userId!, name);
    await loadUserProfile();
  }

  Future<void> recordLearningSession() async {
    if (_userId == null) return;
    final now = DateTime.now();
    await _userRepository.recordSession(_userId!, now);
    await _userRepository.incrementStreak(_userId!, now);
    await loadUserProfile(); // This will now also reload the rank
  }

  Future<List<Map<String, dynamic>>> getTopRankings({int limit = 100}) {
    return _userRepository.getTopRankings(limit: limit);
  }
}
