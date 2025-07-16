import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:memora/domain/usecases/clear_notion_api_token.dart';
import 'package:memora/domain/usecases/clear_notion_database_info.dart';
import 'package:memora/domain/usecases/create_quiz_from_text.dart';
import 'package:memora/domain/usecases/get_database_info.dart';
import 'package:memora/domain/usecases/get_notion_info.dart';
import 'package:memora/domain/usecases/get_page_content.dart';
import 'package:memora/domain/usecases/get_pages_from_db.dart';
import 'package:memora/domain/usecases/get_roadmap_tasks_from_db.dart';
import 'package:memora/domain/usecases/save_notion_api_token.dart';
import 'package:memora/domain/usecases/save_notion_database.dart';
import 'package:memora/domain/usecases/save_notion_database_id.dart';
import 'package:memora/domain/usecases/save_notion_database_title.dart';
import 'package:memora/domain/usecases/search_notion_databases.dart';
import 'package:memora/models/task_model.dart';

class NotionProvider with ChangeNotifier {
  final SaveNotionApiToken _saveNotionApiToken;
  final ClearNotionApiToken _clearNotionApiToken;
  final SaveNotionDatabaseId _saveNotionDatabaseId;
  final SaveNotionDatabaseTitle _saveNotionDatabaseTitle;
  final SaveNotionDatabase _saveNotionDatabase;
  final ClearNotionDatabaseInfo _clearNotionDatabaseInfo;
  final GetNotionInfo _getNotionInfo;
  final GetPagesFromDB _getPagesFromDB;
  final GetDatabaseInfo _getDatabaseInfo;
  final GetPageContent _getPageContent;
  final SearchNotionDatabases _searchNotionDatabases;
  final GetRoadmapTasksFromDB _getRoadmapTasksFromDB;
  final CreateQuizFromText _createQuizFromText;

  NotionProvider({
    required SaveNotionApiToken saveNotionApiToken,
    required ClearNotionApiToken clearNotionApiToken,
    required SaveNotionDatabaseId saveNotionDatabaseId,
    required SaveNotionDatabaseTitle saveNotionDatabaseTitle,
    required SaveNotionDatabase saveNotionDatabase,
    required ClearNotionDatabaseInfo clearNotionDatabaseInfo,
    required GetNotionInfo getNotionInfo,
    required GetPagesFromDB getPagesFromDB,
    required GetDatabaseInfo getDatabaseInfo,
    required GetPageContent getPageContent,
    required SearchNotionDatabases searchNotionDatabases,
    required GetRoadmapTasksFromDB getRoadmapTasksFromDB,
    required CreateQuizFromText createQuizFromText,
  }) : _saveNotionApiToken = saveNotionApiToken,
       _clearNotionApiToken = clearNotionApiToken,
       _saveNotionDatabaseId = saveNotionDatabaseId,
       _saveNotionDatabaseTitle = saveNotionDatabaseTitle,
       _saveNotionDatabase = saveNotionDatabase,
       _clearNotionDatabaseInfo = clearNotionDatabaseInfo,
       _getNotionInfo = getNotionInfo,
       _getPagesFromDB = getPagesFromDB,
       _getDatabaseInfo = getDatabaseInfo,
       _getPageContent = getPageContent,
       _searchNotionDatabases = searchNotionDatabases,
       _getRoadmapTasksFromDB = getRoadmapTasksFromDB,
       _createQuizFromText = createQuizFromText;

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
      notifyListeners();
    });

    try {
      _pages = await _getPagesFromDB.call(_databaseId!);
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
      _availableDatabases = await _searchNotionDatabases.call(query: query);
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
    final notionInfo = await _getNotionInfo.call();
    _apiToken = notionInfo['apiToken'];
    _databaseId = notionInfo['databaseId'];
    _databaseTitle = notionInfo['databaseTitle'];
    _database = notionInfo['database'];

    // If apiToken and databaseId are present, ensure connection status is updated.
    if (_apiToken != null && _databaseId != null) {
      // If title is missing, try fetching it again.
      if (_databaseTitle == null || _databaseTitle!.isEmpty) {
        try {
          final dbInfo = await _getDatabaseInfo.call(_databaseId!);
          final fetchedDbTitle =
              dbInfo['title']?[0]?['plain_text'] ?? 'Untitled';
          if (fetchedDbTitle.isNotEmpty) {
            _databaseTitle = fetchedDbTitle;
            await _saveNotionDatabaseTitle.call(_databaseTitle!);
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
      notifyListeners();
    });
  }

  Future<void> saveDatabase(String database) async {
    await _saveNotionDatabase.call(database);
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return;
    }
    try {
      // Verify the database by fetching its info. This confirms the token has access.
      await _getDatabaseInfo.call(databaseId);

      // If verification is successful, save the new database info.
      await _saveNotionDatabaseId.call(databaseId);
      await _saveNotionDatabaseTitle.call(databaseTitle);
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
      notifyListeners();
    });
  }

  Future<void> setApiToken(String apiToken) async {
    await _saveNotionApiToken.call(apiToken);
    _apiToken = apiToken;
    // After setting a new token, we should clear old database info
    // and errors as they might be invalid.
    _databaseId = null;
    _databaseTitle = null;
    _database = null;
    _pages = [];
    _notionConnectionError = null;
    await _clearNotionDatabaseInfo.call(); // Also clear from storage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<void> clearNotionInfo() async {
    await _clearNotionApiToken.call();
    await _clearNotionDatabaseInfo.call();
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
    return await _getPageContent.call(pageId);
  }

  Future<List<Task>> fetchRoadmapTasks() async {
    if (!isConnected) return [];

    try {
      final notionPages = await _getRoadmapTasksFromDB.call(_databaseId!);
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
        final content = await _getPageContent.call(pageId);

        if (content.trim().isNotEmpty) {
          _currentQuiz = await _createQuizFromText.call(content);
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
