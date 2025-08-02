import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:memora/services/notion_service.dart';
import 'package:memora/services/openai_service.dart';

class NotionProvider with ChangeNotifier {
  final NotionService _notionService;
  final OpenAIService _openAIService;

  NotionProvider({
    required NotionService notionService,
    required OpenAIService openAIService,
  }) : _notionService = notionService,
       _openAIService = openAIService;

  String? _apiToken;
  String? _apiTokenTimestamp;
  String? _databaseId;
  String? _databaseTitle;
  String? _notionConnectionError;
  List<dynamic> _pages = [];
  Map<String, dynamic>? _currentQuiz;
  List<dynamic> _availableDatabases = [];

  bool _arePagesLoading = false;
  bool _isQuizLoading = false;
  bool _isSearchingDatabases = false;
  bool _isLoading = false;

  // Getters
  String? get apiToken => _apiToken;
  String? get apiTokenTimestamp => _apiTokenTimestamp;
  String? get databaseId => _databaseId;
  String? get databaseTitle => _databaseTitle;
  String? get notionConnectionError => _notionConnectionError;
  bool get isConnected =>
      _apiToken != null &&
      _databaseId != null &&
      _notionConnectionError == null;
  Map<String, dynamic>? get currentQuiz => _currentQuiz;
  List<dynamic> get pages => _pages;
  List<dynamic> get availableDatabases => _availableDatabases;
  bool get arePagesLoading => _arePagesLoading;
  bool get isQuizLoading => _isQuizLoading;
  bool get isSearchingDatabases => _isSearchingDatabases;
  bool get isLoading => _isLoading;

  // Methods
  Future<void> initialize() async {
    _isLoading = true;
    Future.microtask(() => notifyListeners());
    try {
      final result = await _notionService.initializeConnection();
      _handleConnectionResult(result);
    } catch (e) {
      _notionConnectionError =
          'Failed to initialize connection: ${e.toString()}';
      _apiToken = null;
      _databaseId = null;
      _databaseTitle = null;
    }
    _isLoading = false;
    Future.microtask(() => notifyListeners());
  }

  Future<void> fetchNotionPages() async {
    if (!isConnected) return;
    _arePagesLoading = true;
    _pages = []; // Clear existing pages
    Future.microtask(() => notifyListeners());

    try {
      String? nextCursor;
      bool hasMore;

      do {
        final response = await _notionService.getPagesFromDB(
          _databaseId!,
          nextCursor,
        );
        final results = response['results'] as List<dynamic>;
        _pages.addAll(results);

        hasMore = response['has_more'] as bool;
        nextCursor = response['next_cursor'] as String?;

        _arePagesLoading =
            hasMore; // Keep loading indicator if there are more pages
        Future.microtask(() => notifyListeners());
      } while (hasMore);

      _notionConnectionError = null;
    } catch (e) {
      _pages = [];
      _notionConnectionError = 'Notion 페이지 로딩 오류: 다시 시도해주세요.';
    } finally {
      _arePagesLoading = false;
      Future.microtask(() => notifyListeners());
    }
  }

  Future<void> searchNotionDatabases({String? query}) async {
    if (_apiToken == null) {
      _notionConnectionError = 'Notion API 토큰이 설정되지 않았습니다.';
      Future.microtask(() => notifyListeners());
      return;
    }

    _isSearchingDatabases = true;
    _availableDatabases = [];
    Future.microtask(() => notifyListeners());

    try {
      _availableDatabases = await _notionService.searchDatabases(query: query);
      _notionConnectionError = null;
    } catch (e) {
      _notionConnectionError = '데이터베이스 검색 오류: API 토큰을 확인해주세요.';
      _availableDatabases = [];
    }

    _isSearchingDatabases = false;
    Future.microtask(() => notifyListeners());
  }

  Future<void> connectNotionDatabase(String dbId, String dbTitle) async {
    _isLoading = true;
    Future.microtask(() => notifyListeners());
    if (_apiToken == null) {
      _notionConnectionError = 'Notion API 토큰이 설정되지 않았습니다.';
      _isLoading = false;
      Future.microtask(() => notifyListeners());
      return;
    }
    try {
      final result = await _notionService.connectDatabase(dbId, dbTitle);
      _databaseId = result['databaseId'];
      _databaseTitle = result['databaseTitle'];
      _notionConnectionError = null;
    } catch (e) {
      _notionConnectionError = 'Failed to connect to database: ${e.toString()}';
    }
    _isLoading = false;
    Future.microtask(() => notifyListeners());
  }

  Future<void> setApiToken(String apiToken) async {
    _isLoading = true;
    Future.microtask(() => notifyListeners());
    await _notionService.updateApiToken(apiToken);
    await initialize(); // This will set isLoading to false and notify listeners
  }

  Future<void> fetchNewQuiz() async {
    if (!isConnected) return;
    _isQuizLoading = true;
    _currentQuiz = null;
    Future.microtask(() => notifyListeners());

    try {
      if (_pages.isEmpty) await fetchNotionPages();

      if (_pages.isNotEmpty) {
        final randomPage = _pages[Random().nextInt(_pages.length)];
        final pageId = randomPage['id'];
        final content = await _notionService.getPageContent(pageId);

        if (content.trim().isNotEmpty) {
          _currentQuiz = await _openAIService.createQuizFromText(content);
        } else {
          fetchNewQuiz(); // Retry with another page if content is empty
        }
      }
    } catch (e) {
      _currentQuiz = null;
    }

    _isQuizLoading = false;
    Future.microtask(() => notifyListeners());
  }

  Future<String> getPageContent(String pageId) async {
    if (!isConnected) throw Exception('Notion is not connected.');
    return await _notionService.getPageContent(pageId);
  }

  void _handleConnectionResult(Map<String, String?> result) {
    _apiToken = result['apiToken'];
    _apiTokenTimestamp = result['apiTokenTimestamp'];
    _databaseId = result['databaseId'];
    _databaseTitle = result['databaseTitle'];
    if (_apiToken == null) {
      _notionConnectionError = 'Notion API 토큰을 찾을 수 없습니다. 설정에서 추가해주세요.';
    } else {
      _notionConnectionError = null;
    }
  }

  Future<String> renderNotionDbAsMarkdown(String pageId) async {
    if (!isConnected) throw Exception('Notion is not connected.');
    return await _notionService.renderNotionDbAsMarkdown(pageId);
  }
}
