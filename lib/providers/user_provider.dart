import 'package:flutter/material.dart';
import 'package:memora/domain/usecases/user_usecases.dart';

class UserProvider with ChangeNotifier {
  final UserUsecases _userUsecases;

  String? _userLevel;
  String? _levelTimestamp;
  int _streakCount = 0;
  Map<String, int> _sessionMap = {};
  bool _isLoading = true;
  String? _userId;

  String? get userLevel => _userLevel;
  String? get levelTimestamp => _levelTimestamp;
  int get streakCount => _streakCount;
  Map<String, int> get sessionMap => _sessionMap;
  bool get isLoading => _isLoading;
  // Use a getter with a null check to ensure userId is initialized before use.
  String get userId {
    if (_userId == null) {
      throw StateError(
        'User ID has not been initialized. Call initializeUser first.',
      );
    }
    return _userId!;
  }

  UserProvider({required UserUsecases userUsecases})
    : _userUsecases = userUsecases {
    initializeUser();
  }

  /// Initializes the user by fetching or creating a user ID, then loads profile data.
  Future<void> initializeUser() async {
    _isLoading = true;
    Future.microtask(() => notifyListeners());

    _userId = await _userUsecases.getOrCreateUserId();
    await loadUserProfile();
  }

  Future<void> loadUserProfile() async {
    _isLoading = true;
    Future.microtask(() => notifyListeners());

    // Ensure we have a userId before proceeding
    if (_userId == null) {
      // If userId is somehow null, stop loading and exit loading state.
      _isLoading = false;
      Future.microtask(() => notifyListeners());
      return;
    }

    final data = await _userUsecases.loadUserLevelWithTimestamp(userId);
    _userLevel = data['level'];
    _levelTimestamp = data['timestamp'];
    _streakCount = await _userUsecases.loadStreakCount(userId);
    _sessionMap = await _userUsecases.loadSessionMap(userId);

    _isLoading = false;
    Future.microtask(() => notifyListeners());
  }

  Future<void> saveUserLevel(String level) async {
    await _userUsecases.saveUserLevel(userId, level);
    await loadUserProfile();
  }

  /// Records a learning session and updates the profile state.
  Future<void> recordLearningSession() async {
    final now = DateTime.now();
    await _userUsecases.recordSession(userId, now);
    await _userUsecases.incrementStreak(userId, now);
    // Reload all profile data to ensure consistency
    await loadUserProfile();
  }
}
