import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:memora/models/proficiency_level.dart';
import 'package:memora/repositories/ranking/ranking_repository.dart';
import 'package:memora/repositories/user/user_repository.dart';
import 'package:memora/screens/settings/ai_model_settings_screen.dart';
import 'package:memora/services/encryption_service.dart';
import 'package:memora/services/local_storage_service.dart';

class UserProvider with ChangeNotifier {
  final UserRepository _userRepository;
  final RankingRepository _rankingRepository;
  final LocalStorageService _localStorageService;

  ProficiencyLevel? _userLevel;
  String? _displayName;
  String? _email;
  String? _photoURL;
  String? _levelTimestamp;
  int _streakCount = 0;
  Map<String, int> _sessionMap = {};
  int? _userRank;
  bool _isLoading = true;
  String? _userId;
  User? _user;
  AiProvider _preferredAi = AiProvider.gemini;

  ProficiencyLevel? get userLevel => _userLevel;
  String? get displayName => _displayName;
  String? get email => _email;
  String? get photoURL => _photoURL;
  String? get levelTimestamp => _levelTimestamp;
  int get streakCount => _streakCount;
  Map<String, int> get sessionMap => _sessionMap;
  int? get userRank => _userRank;
  bool get isLoading => _isLoading;
  String? get userId => _userId;
  User? get user => _user;
  AiProvider get preferredAi => _preferredAi;

  bool get isProfileComplete => _userLevel != null;

  UserProvider({
    required UserRepository userRepository,
    required RankingRepository rankingRepository,
    required LocalStorageService localStorageService,
  })  : _userRepository = userRepository,
        _rankingRepository = rankingRepository,
        _localStorageService = localStorageService {
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _user = user;
      if (user != null) {
        _userId = user.uid;
        loadUserProfile();
      } else {
        _resetState();
      }
    });
  }

  void _resetState() {
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
    _preferredAi = AiProvider.gemini;
    Future.microtask(() => notifyListeners());
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
      await _userRepository.ensureStreakCountExists(_userId!);

      final firestoreData = await _userRepository.getUserData(_userId!);
      if (firestoreData != null) {
        if (firestoreData.containsKey('level')) {
          _userLevel = ProficiencyLevel.fromString(firestoreData['level']);
        } else {
          _userLevel = null;
        }
        _displayName = firestoreData['displayName'];
        _email = firestoreData['email'];
        _photoURL = firestoreData['photoURL'];
        _streakCount = firestoreData['streakCount'] ?? 0;
        final preferredAiString = firestoreData['preferredAi'];
        if (preferredAiString == 'openai') {
          _preferredAi = AiProvider.openai;
        } else {
          _preferredAi = AiProvider.gemini;
        }
      } else {
        _userLevel = null;
        _preferredAi = AiProvider.gemini;
      }

      await _syncApiKeysFromFirestore();

      await Future.wait([
        if (_userLevel == null)
          _userRepository.loadUserLevelWithTimestamp(_userId!).then((data) {
            _userLevel = ProficiencyLevel.fromString(data['level']);
            _levelTimestamp = data['timestamp'];
          }).catchError((_) {
            _userLevel = null;
            _levelTimestamp = null;
          }),
        if (_displayName == null)
          _userRepository
              .loadUserName(_userId!)
              .then((name) => _displayName = name),
        if (_email == null)
          _userRepository.loadUserEmail(_userId!).then((email) => _email = email),
        if (_photoURL == null)
          _userRepository
              .loadUserPhotoUrl(_userId!)
              .then((photoUrl) => _photoURL = photoUrl),
        _userRepository
            .loadStreakCount(_userId!)
            .then((count) => _streakCount = count),
        _userRepository
            .loadSessionMap(_userId!)
            .then((map) => _sessionMap = map),
        _userRepository.loadPreferredAi(_userId!).then((preferredAi) {
          if (preferredAi == 'openai') {
            _preferredAi = AiProvider.openai;
          } else {
            _preferredAi = AiProvider.gemini;
          }
        }),
      ]);

      _rankingRepository.getUserRank(_userId!).then((rank) {
        _userRank = rank;
        notifyListeners();
      }).catchError((_) {
        _userRank = null;
      });
    } catch (e) {
      if (kDebugMode) {
        print("An unexpected error occurred while loading user profile: $e");
      }
    } finally {
      _isLoading = false;
      Future.microtask(() => notifyListeners());
    }
  }

  Future<void> setPreferredAi(AiProvider provider) async {
    if (_userId == null) return;
    _preferredAi = provider;
    notifyListeners();
    await _userRepository.savePreferredAi(_userId!, provider.name);
  }

  /// Fetches encrypted keys from Firestore, decrypts them, and saves to local storage.
  Future<void> _syncApiKeysFromFirestore() async {
    if (_userId == null) return;

    try {
      final encryptedKeys = await _userRepository.loadEncryptedApiKeys(
        _userId!,
      );
      if (encryptedKeys.isEmpty) return;

      final encryptionService = EncryptionService(_userId!);

      for (final entry in encryptedKeys.entries) {
        final serviceName = entry.key;
        final encryptedValue = entry.value;

        if (encryptedValue.isNotEmpty) {
          final decryptedValue = encryptionService.decrypt(encryptedValue);
          if (decryptedValue.isNotEmpty) {
            await _localStorageService.saveApiKeyWithTimestamp(
              serviceName,
              decryptedValue,
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error syncing API keys from Firestore: $e");
      }
    }
  }

  /// Encrypts all local API keys and saves them to Firestore.
  Future<void> syncAllApiKeysToFirestore() async {
    if (_userId == null) return;

    try {
      final encryptionService = EncryptionService(_userId!);
      final Map<String, String> encryptedKeys = {};

      final services = ['notion', 'openai', 'gemini'];

      for (final service in services) {
        final keyData = await _localStorageService.getApiKeyWithTimestamp(
          service,
        );
        final plainKey = keyData['value'];

        if (plainKey != null && plainKey.isNotEmpty) {
          encryptedKeys[service] = encryptionService.encrypt(plainKey);
        }
      }

      if (encryptedKeys.isNotEmpty) {
        await _userRepository.saveEncryptedApiKeys(_userId!, encryptedKeys);
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error syncing API keys to Firestore: $e");
      }
      rethrow;
    }
  }

  Future<void> saveUserLevel(ProficiencyLevel level) async {
    if (_userId == null) return;

    // Update local state immediately for better UI responsiveness
    _userLevel = level;
    notifyListeners();

    try {
      await _userRepository.saveUserLevel(_userId!, level);
      await loadUserProfile();
    } catch (e) {
      if (kDebugMode) {
        print("Error saving user level: $e");
      }
    }
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

  Stream<List<Map<String, dynamic>>> getTopRankings({int limit = 100}) {
    return _rankingRepository.getTopRankings(limit: limit);
  }
}
