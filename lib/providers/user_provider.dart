import 'package:firebase_auth/firebase_auth.dart';
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
  bool _isLoading = true; // Start with loading true
  String? _userId;

  ProficiencyLevel? get userLevel => _userLevel;
  String? get displayName => _displayName;
  String? get levelTimestamp => _levelTimestamp;
  int get streakCount => _streakCount;
  Map<String, int> get sessionMap => _sessionMap;
  bool get isLoading => _isLoading;
  String? get userId => _userId; // Make it nullable

  UserProvider({required UserRepository userRepository})
    : _userRepository = userRepository {
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _userId = user.uid;
        loadUserProfile(); // Load data for the new user
      } else {
        // User is logged out, reset state
        _userId = null;
        _userLevel = null;
        _displayName = null;
        _levelTimestamp = null;
        _streakCount = 0;
        _sessionMap = {};
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> loadUserProfile() async {
    if (_userId == null) return;

    _isLoading = true;
    notifyListeners();

    final data = await _userRepository.loadUserLevelWithTimestamp(_userId!);
    _userLevel = ProficiencyLevel.fromString(data['level']);
    _levelTimestamp = data['timestamp'];
    _displayName = await _userRepository.loadUserName(_userId!);
    _streakCount = await _userRepository.loadStreakCount(_userId!);
    _sessionMap = await _userRepository.loadSessionMap(_userId!);

    _isLoading = false;
    notifyListeners();
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
    await loadUserProfile();
  }
}
