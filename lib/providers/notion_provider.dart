import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:memora/models/task_model.dart';
import 'package:memora/services/notion_service.dart';
import 'package:memora/services/openai_service.dart';

class NotionProvider with ChangeNotifier {
  final NotionService _notionService = NotionService();
  final OpenAIService _openAIService = OpenAIService();
  String? _apiToken;
  String? _databaseId;
  String? _databaseTitle;
  String? _database; // New field for database value
  String? _notionConnectionError; // New field for connection errors
  List<dynamic> _pages = [];
  Map<String, dynamic>? _currentQuiz;
  bool _isQuizLoading = false;
  List<dynamic> _availableDatabases = [];
  bool _isSearchingDatabases = false;

  String? get apiToken => _apiToken;
  String? get databaseId => _databaseId;
  String? get databaseTitle => _databaseTitle;
  String? get database => _database; // New getter
  String? get notionConnectionError => _notionConnectionError; // New getter
  bool get isConnected =>
      _apiToken != null &&
      _databaseId != null &&
      _database != null &&
      _notionConnectionError == null;
  Map<String, dynamic>? get currentQuiz => _currentQuiz;
  bool get isQuizLoading => _isQuizLoading;
  List<dynamic> get availableDatabases => _availableDatabases;
  bool get isSearchingDatabases => _isSearchingDatabases;
  List<dynamic> get pages => _pages; // Add this line

  NotionProvider() {
    // Removed _loadNotionInfo() from constructor to prevent setState during build errors.
    // It will be called explicitly after provider creation in main.dart.
  }

  Future<void> initialize() async {
    await _loadNotionInfo();
  }

  bool _arePagesLoading = false;
  bool get arePagesLoading => _arePagesLoading;

  Future<void> fetchNotionPages() async {
    if (!isConnected) return;
    _arePagesLoading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      _pages = await _notionService.getPagesFromDB(_apiToken!, _databaseId!);
      _notionConnectionError = null; // Clear error on success
    } catch (e) {
      debugPrint('Error fetching pages from Notion: $e');
      _pages = [];
      _notionConnectionError =
          'Notion 연결 오류: ${e.toString().contains('unauthorized') ? 'API 토큰이 유효하지 않습니다.' : '다시 시도해주세요.'}';
    }

    _arePagesLoading = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<void> searchNotionDatabases({String? query}) async {
    if (_apiToken == null) {
      _notionConnectionError = 'Notion API 토큰이 설정되지 않았습니다.';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return;
    }

    _isSearchingDatabases = true;
    _availableDatabases = []; // Clear previous results
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      _availableDatabases = await _notionService.searchDatabases(
        _apiToken!,
        query: query,
      );
      _notionConnectionError = null; // Clear error on success
    } catch (e) {
      debugPrint('Error searching databases: $e');
      _notionConnectionError =
          '데이터베이스 검색 오류: ${e.toString().contains('unauthorized') ? 'API 토큰이 유효하지 않습니다.' : '다시 시도해주세요.'}';
      _availableDatabases = [];
    }

    _isSearchingDatabases = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<void> _loadNotionInfo() async {
    _notionConnectionError = null; // Clear previous error
    final notionInfo = await _notionService.getNotionInfo();
    _apiToken = notionInfo['apiToken'];
    _databaseId = notionInfo['databaseId'];
    _databaseTitle = notionInfo['databaseTitle'];
    _database = notionInfo['database'];

    // If apiToken and databaseId are present but databaseTitle is not, try to fetch it.
    if (_apiToken != null &&
        _databaseId != null &&
        (_databaseTitle == null || _databaseTitle!.isEmpty)) {
      try {
        final dbInfo = await _notionService.getDatabaseInfo(
          _apiToken!,
          _databaseId!,
        );
        debugPrint('Notion DB Info (from _loadNotionInfo): $dbInfo');
        final fetchedDbTitle = dbInfo['title']?[0]?['plain_text'] ?? 'Untitled';
        debugPrint('Fetched DB Title (from _loadNotionInfo): $fetchedDbTitle');
        if (fetchedDbTitle.isNotEmpty) {
          _databaseTitle = fetchedDbTitle;
          // Save the fetched title back to NotionService (which saves to SharedPreferences)
          await _notionService.saveDatabaseTitle(_databaseTitle!);
        }
        _notionConnectionError = null; // Clear error on success
      } catch (e) {
        debugPrint('Error fetching database title on load: $e');
        _notionConnectionError =
            'Notion 연결 오류: ${e.toString().contains('unauthorized') ? 'API 토큰이 유효하지 않습니다.' : '다시 시도해주세요.'}';
      }
    }
  }

  Future<void> saveDatabase(String database) async {
    await _notionService.saveDatabase(database);
    _database = database;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<void> connectNotionDatabase(
    String databaseId,
    String databaseTitle,
  ) async {
    _notionConnectionError = null; // Clear previous error
    if (_apiToken == null) {
      _notionConnectionError = 'Notion API 토큰이 설정되지 않았습니다.';
      notifyListeners();
      return;
    }
    try {
      // Verify the database by fetching its info. This confirms the token has access.
      await _notionService.getDatabaseInfo(_apiToken!, databaseId);

      // If verification is successful, save the new database info.
      await _notionService.saveDatabaseId(databaseId);
      await _notionService.saveDatabaseTitle(databaseTitle);
      _databaseId = databaseId;
      _databaseTitle = databaseTitle;
      _notionConnectionError = null; // Clear error on success
    } catch (e) {
      debugPrint('Error connecting Notion database: $e');
      // Don't update to the new ID if it fails. Keep the old one.
      _notionConnectionError =
          '데이터베이스 연결에 실패했습니다. API 토큰이 해당 데이터베이스에 대한 접근 권한을 가지고 있는지 확인해주세요.';
    }
    notifyListeners();
  }

  Future<void> setApiToken(String apiToken) async {
    await _notionService.saveApiToken(apiToken);
    _apiToken = apiToken;
    // After setting a new token, we should clear old database info
    // and errors as they might be invalid.
    _databaseId = null;
    _databaseTitle = null;
    _database = null;
    _pages = [];
    _notionConnectionError = null;
    await _notionService.clearDatabaseInfo(); // Also clear from storage
    notifyListeners();
  }

  Future<void> clearNotionInfo() async {
    await _notionService.clearNotionInfo();
    _apiToken = null;
    _databaseId = null;
    _databaseTitle = null;
    _database = null;
    _pages = [];
    _currentQuiz = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<String> getPageContent(String pageId) async {
    if (!isConnected) throw Exception('Notion is not connected.');
    return await _notionService.getPageContent(pageId, _apiToken!);
  }

  Future<List<Task>> fetchRoadmapTasks() async {
    if (!isConnected) return [];

    try {
      final notionPages = await _notionService.getRoadmapTasksFromDB(
        _apiToken!,
        _databaseId!,
      );
      return notionPages.map((json) => Task.fromNotion(json)).toList();
    } catch (e) {
      debugPrint('Error fetching roadmap tasks from Notion: $e');
      return [];
    }
  }

  Future<void> fetchNewQuiz() async {
    if (!isConnected) return;
    _isQuizLoading = true;
    _currentQuiz = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      if (_pages.isEmpty) {
        await fetchNotionPages(); // Use the new method
      }

      if (_pages.isNotEmpty) {
        final randomPage = _pages[Random().nextInt(_pages.length)];
        final pageId = randomPage['id'];
        final content = await _notionService.getPageContent(pageId, _apiToken!);

        if (content.trim().isNotEmpty) {
          _currentQuiz = await _openAIService.createQuizFromText(content);
        } else {
          // Handle empty content, maybe fetch another page
          fetchNewQuiz();
        }
      }
    } catch (e) {
      // Consider using a logging framework here instead of print(e) for production.
      _currentQuiz = null;
    }

    _isQuizLoading = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}
