import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:memora/domain/usecases/notion_usecases.dart';
import 'package:memora/domain/usecases/openai_usecases.dart';
import 'package:memora/models/task_model.dart';

class NotionProvider with ChangeNotifier {
  final NotionUsecases _notionUsecases;
  final OpenAIUsecases _openAIUsecases;

  NotionProvider({
    required NotionUsecases notionUsecases,
    required OpenAIUsecases openAIUsecases,
  }) : _notionUsecases = notionUsecases,
       _openAIUsecases = openAIUsecases;

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
  List<dynamic> get pages => _pages;

  Future<void> initialize() async {
    await _loadNotionInfo();
  }

  bool _arePagesLoading = false;
  bool get arePagesLoading => _arePagesLoading;

  Future<void> fetchNotionPages() async {
    if (!isConnected) return;
    _arePagesLoading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.microtask(() => notifyListeners());
    });

    try {
      _pages = await _notionUsecases.getPagesFromDB(_databaseId!);
      _notionConnectionError = null; // Clear error on success
    } catch (e) {
      debugPrint('Error fetching pages from Notion: $e');
      _pages = [];
      _notionConnectionError =
          'Notion 연결 오류: ${e.toString().contains('unauthorized') ? 'API 토큰이 유효하지 않습니다.' : '다시 시도해주세요.'}';
    }

    _arePagesLoading = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.microtask(() => notifyListeners());
    });
  }

  Future<void> searchNotionDatabases({String? query}) async {
    if (_apiToken == null) {
      _notionConnectionError = 'Notion API 토큰이 설정되지 않았습니다.';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.microtask(() => notifyListeners());
      });
      return;
    }

    _isSearchingDatabases = true;
    _availableDatabases = []; // Clear previous results
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.microtask(() => notifyListeners());
    });

    try {
      _availableDatabases = await _notionUsecases.searchDatabases(query: query);
      _notionConnectionError = null; // Clear error on success
    } catch (e) {
      debugPrint('Error searching databases: $e');
      _notionConnectionError =
          '데이터베이스 검색 오류: ${e.toString().contains('unauthorized') ? 'API 토큰이 유효하지 않습니다.' : '다시 시도해주세요.'}';
      _availableDatabases = [];
    }

    _isSearchingDatabases = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.microtask(() => notifyListeners());
    });
  }

  Future<void> _loadNotionInfo() async {
    _notionConnectionError = null; // Clear previous error
    final notionInfo = await _notionUsecases.getNotionInfo();
    _apiToken = notionInfo['apiToken'];
    _databaseId = notionInfo['databaseId'];
    _databaseTitle = notionInfo['databaseTitle'];
    _database = notionInfo['database'];

    // If apiToken and databaseId are present, ensure connection status is updated.
    if (_apiToken != null && _databaseId != null) {
      // If title is missing, try fetching it again.
      if (_databaseTitle == null || _databaseTitle!.isEmpty) {
        try {
          final dbInfo = await _notionUsecases.getDatabaseInfo(_databaseId!);
          final fetchedDbTitle =
              dbInfo['title']?[0]?['plain_text'] ?? 'Untitled';
          if (fetchedDbTitle.isNotEmpty) {
            _databaseTitle = fetchedDbTitle;
            await _notionUsecases.saveDatabaseTitle(_databaseTitle!);
          }
        } catch (e) {
          debugPrint('Error fetching database title on load: $e');
          _notionConnectionError = '저장된 데이터베이스를 불러오는 데 실패했습니다. 다시 연결해주세요.';
          // Clear invalid info
          await clearNotionInfo();
        }
      }
    } else {
      // If essential info is missing, ensure we are not considered connected.
      _apiToken = null;
      _databaseId = null;
      _databaseTitle = null;
      _database = null;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.microtask(() => notifyListeners());
    });
  }

  Future<void> saveDatabase(String database) async {
    await _notionUsecases.saveDatabase(database);
    _database = database;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.microtask(() => notifyListeners());
    });
  }

  Future<void> connectNotionDatabase(
    String databaseId,
    String databaseTitle,
  ) async {
    _notionConnectionError = null; // Clear previous error
    if (_apiToken == null) {
      _notionConnectionError = 'Notion API 토큰이 설정되지 않았습니다.';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.microtask(() => notifyListeners());
      });
      return;
    }
    try {
      // Verify the database by fetching its info. This confirms the token has access.
      await _notionUsecases.getDatabaseInfo(databaseId);

      // If verification is successful, save the new database info.
      await _notionUsecases.saveDatabaseId(databaseId);
      await _notionUsecases.saveDatabaseTitle(databaseTitle);
      _databaseId = databaseId;
      _databaseTitle = databaseTitle;
      _notionConnectionError = null; // Clear error on success

      // Also update the general 'database' field for consistency
      final dbValue = json.encode({'id': databaseId, 'title': databaseTitle});
      await saveDatabase(dbValue);
    } catch (e) {
      debugPrint('Error connecting Notion database: $e');
      // Don't update to the new ID if it fails. Keep the old one.
      _notionConnectionError =
          '데이터베이스 연결에 실패했습니다. API 토큰이 해당 데이터베이스에 대한 접근 권한을 가지고 있는지 확인해주세요.';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.microtask(() => notifyListeners());
    });
  }

  Future<void> setApiToken(String apiToken) async {
    await _notionUsecases.saveApiToken(apiToken);
    _apiToken = apiToken;
    // After setting a new token, we should clear old database info
    // and errors as they might be invalid.
    _databaseId = null;
    _databaseTitle = null;
    _database = null;
    _pages = [];
    _notionConnectionError = null;
    await _notionUsecases.clearDatabaseInfo(); // Also clear from storage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.microtask(() => notifyListeners());
    });
  }

  Future<void> clearNotionInfo() async {
    await _notionUsecases.clearApiToken();
    await _notionUsecases.clearDatabaseInfo();
    _apiToken = null;
    _databaseId = null;
    _databaseTitle = null;
    _database = null;
    _pages = [];
    _currentQuiz = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.microtask(() => notifyListeners());
    });
  }

  Future<String> getPageContent(String pageId) async {
    if (!isConnected) throw Exception('Notion is not connected.');
    return await _notionUsecases.getPageContent(pageId);
  }

  Future<List<Task>> fetchRoadmapTasks() async {
    if (!isConnected) return [];

    try {
      final notionPages = await _notionUsecases.getRoadmapTasksFromDB(
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
      Future.microtask(() => notifyListeners());
    });

    try {
      if (_pages.isEmpty) {
        await fetchNotionPages(); // Use the new method
      }

      if (_pages.isNotEmpty) {
        final randomPage = _pages[Random().nextInt(_pages.length)];
        final pageId = randomPage['id'];
        final content = await _notionUsecases.getPageContent(pageId);

        if (content.trim().isNotEmpty) {
          _currentQuiz = await _openAIUsecases.createQuizFromText(content);
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
      Future.microtask(() => notifyListeners());
    });
  }

  Future<String> renderNotionDbAsMarkdown(String pageId) async {
    if (!isConnected) throw Exception('Notion is not connected.');
    return await _notionUsecases.renderNotionDbAsMarkdown(pageId);
  }
}
