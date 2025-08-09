import 'dart:math';

import 'package:flutter/widgets.dart';
import 'dart:convert';
import 'package:memora/models/notion_database.dart';
import 'package:memora/models/notion_page.dart';
import 'package:memora/services/gemini_service.dart';
import 'package:memora/services/notion_service.dart';
import 'package:memora/services/openai_service.dart';
import 'package:memora/models/quiz_question.dart';

class NotionProvider with ChangeNotifier {
  final NotionService _notionService;
  final OpenAIService _openAIService;
  final GeminiService _geminiService;

  NotionProvider({
    required NotionService notionService,
    required OpenAIService openAIService,
    required GeminiService geminiService,
  }) : _notionService = notionService,
       _openAIService = openAIService,
       _geminiService = geminiService;

  String? _apiToken;
  String? _apiTokenTimestamp;
  String? _databaseId;
  String? _databaseTitle;
  String? _notionConnectionError;
  List<NotionPage> _pages = [];
  QuizQuestion? _currentQuiz;
  List<NotionDatabase> _availableDatabases = [];

  bool _arePagesLoading = false;
  bool _isQuizLoading = false;
  bool _isSearchingDatabases = false;
  bool _isLoading = false;

  // --- TIL Review Selection State ---
  final Set<String> _selectedPageIds = {};
  bool _isFetchingCombinedContent = false;
  List<NotionPage> _combinedPageContent = [];

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
  QuizQuestion? get currentQuiz => _currentQuiz;
  List<NotionPage> get pages => _pages;
  List<NotionDatabase> get availableDatabases => _availableDatabases;
  bool get arePagesLoading => _arePagesLoading;
  bool get isQuizLoading => _isQuizLoading;
  bool get isSearchingDatabases => _isSearchingDatabases;
  bool get isLoading => _isLoading;

  // --- TIL Review Selection Getters ---
  Set<String> get selectedPageIds => _selectedPageIds;
  bool get isFetchingCombinedContent => _isFetchingCombinedContent;
  List<NotionPage> get combinedPageContent => _combinedPageContent;

  // --- TIL Review Selection Methods ---
  void togglePageSelection(String pageId) {
    if (_selectedPageIds.contains(pageId)) {
      _selectedPageIds.remove(pageId);
    } else {
      _selectedPageIds.add(pageId);
    }
    Future.microtask(() => notifyListeners());
  }

  void clearPageSelection() {
    _selectedPageIds.clear();
    _combinedPageContent = [];
    Future.microtask(() => notifyListeners());
  }

  Future<bool> fetchCombinedContent() async {
    if (_selectedPageIds.isEmpty) return false;

    _isFetchingCombinedContent = true;
    _combinedPageContent = [];
    Future.microtask(() => notifyListeners());

    final List<NotionPage> selectedPages = [];
    final selectedPagesMeta = _pages
        .where((page) => _selectedPageIds.contains(page.id))
        .toList();

    try {
      for (var pageMeta in selectedPagesMeta) {
        final pageId = pageMeta.id;
        final title = pageMeta.title;
        final content = await getPageContent(pageId);
        selectedPages.add(
          NotionPage(id: pageId, title: title, content: content),
        );
      }
      _combinedPageContent = selectedPages;
      return true;
    } catch (e) {
      _notionConnectionError = '페이지 내용을 불러오는 데 실패했습니다: ${e.toString()}';
      return false;
    } finally {
      _isFetchingCombinedContent = false;
      Future.microtask(() => notifyListeners());
    }
  }

  // --- General Methods ---
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
        final responseMap = await _notionService.getPagesFromDB(
          _databaseId!,
          nextCursor,
        );
        final results = responseMap['results'] as List<dynamic>;
        _pages.addAll(
          results
              .map((e) => NotionPage.fromMap(e as Map<String, dynamic>))
              .toList(),
        );

        hasMore = responseMap['has_more'] as bool;
        nextCursor = responseMap['next_cursor'] as String?;

        _arePagesLoading = hasMore;
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
      final rawDatabases = await _notionService.searchDatabases(query: query);
      _availableDatabases = (rawDatabases['results'] as List)
          .map((db) => NotionDatabase.fromMap(db as Map<String, dynamic>))
          .toList();
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
    await initialize();
  }

  Future<void> fetchNewQuiz() async {
    if (!isConnected) return;
    _isQuizLoading = true;
    _currentQuiz = null;
    Future.microtask(() => notifyListeners());

    try {
      if (_pages.isEmpty) {
        await fetchNotionPages();
      }

      if (_pages.isNotEmpty) {
        final randomPage = _pages[Random().nextInt(_pages.length)];
        final pageId = randomPage.id;
        final content = await getPageContent(pageId);

        if (content.trim().isNotEmpty) {
          final useGemini = await _geminiService.checkApiKeyAvailability();
          if (useGemini) {
            final quizJsonString = await _geminiService.createQuizFromText(
              content,
            );
            final quizMap = json.decode(quizJsonString);
            _currentQuiz = QuizQuestion.fromJson(quizMap);
          } else {
            final quizMap = await _openAIService.createQuizFromText(content);
            _currentQuiz = QuizQuestion.fromJson(quizMap);
          }
        } else {
          fetchNewQuiz();
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
      _notionConnectionError = '설정에서 Notion API 토큰을 추가해주세요.';
    } else {
      _notionConnectionError = null;
    }
  }

  Future<String> renderNotionDbAsMarkdown(String pageId) async {
    if (!isConnected) throw Exception('Notion is not connected.');
    return await _notionService.renderNotionDbAsMarkdown(pageId);
  }
}
