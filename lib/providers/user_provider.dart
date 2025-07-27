import 'package:flutter/material.dart';
import 'package:memora/models/proficiency_level.dart';
import 'package:memora/repositories/user/user_repository.dart';

class UserProvider with ChangeNotifier {
  final UserRepository _userRepository;

  ProficiencyLevel? _userLevel;
  String? _displayName;
  String? _levelTimestamp;
  int _streakCount = 0;
  Map<String, int> _sessionMap = {};
  bool _isLoading = true;
  String? _userId;

  ProficiencyLevel? get userLevel => _userLevel;
  String? get displayName => _displayName;
  String? get levelTimestamp => _levelTimestamp;
  int get streakCount => _streakCount;
  Map<String, int> get sessionMap => _sessionMap;
  bool get isLoading => _isLoading;
  String get userId {
    if (_userId == null) {
      throw StateError(
        'User ID has not been initialized. Call initializeUser first.',
      );
    }
    return _userId!;
  }

  UserProvider({required UserRepository userRepository})
    : _userRepository = userRepository {
    initializeUser();
  }

  Future<void> initializeUser() async {
    _isLoading = true;
    Future.microtask(() => notifyListeners());

    _userId = await _userRepository.getOrCreateUserId();
    await loadUserProfile();
  }

  Future<void> loadUserProfile() async {
    _isLoading = true;
    Future.microtask(() => notifyListeners());

    if (_userId == null) {
      _isLoading = false;
      Future.microtask(() => notifyListeners());
      return;
    }

    final data = await _userRepository.loadUserLevelWithTimestamp(userId);
    _userLevel = ProficiencyLevel.fromString(data['level']);
    _levelTimestamp = data['timestamp'];
    _displayName = await _userRepository.loadUserName(userId);
    _streakCount = await _userRepository.loadStreakCount(userId);
    _sessionMap = await _userRepository.loadSessionMap(userId);

    _isLoading = false;
    Future.microtask(() => notifyListeners());
  }

  Future<void> saveUserLevel(ProficiencyLevel level) async {
    await _userRepository.saveUserLevel(userId, level);
    await loadUserProfile();
  }

  Future<void> saveUserName(String name) async {
    await _userRepository.saveUserName(userId, name);
    await loadUserProfile();
  }

  Future<void> recordLearningSession() async {
    final now = DateTime.now();
    await _userRepository.recordSession(userId, now);
    await _userRepository.incrementStreak(userId, now);
    await loadUserProfile();
  }
}
