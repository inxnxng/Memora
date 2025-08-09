import 'package:flutter/material.dart';
import 'package:memora/constants/heatmap_colors.dart';
import 'package:memora/constants/storage_keys.dart';
import 'package:memora/models/task_model.dart';
import 'package:memora/services/settings_service.dart';
import 'package:memora/services/task_service.dart';

class TaskProvider with ChangeNotifier {
  final TaskService _taskService;
  final SettingsService _settingsService;
  final String? _notionDatabaseId;

  List<Task> _tasks = [];
  bool _isLoading = true;
  Map<DateTime, List<Map<String, dynamic>>> _heatmapData = {};

  // Heatmap specific state
  Color _heatmapColor = heatmapColorOptions
      .firstWhere((c) => c.name == StorageKeys.defaultHeatmapColor)
      .color;
  DateTime? _heatmapStartDate;
  DateTime? _heatmapEndDate;

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      Future.microtask(() => super.notifyListeners());
    }
  }

  TaskProvider({
    required TaskService taskService,
    required SettingsService settingsService,
    String? notionDatabaseId,
  }) : _taskService = taskService,
       _settingsService = settingsService,
       _notionDatabaseId = notionDatabaseId {
    _initialize();
  }

  // --- Public Getters ---
  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  double get progress => _tasks.isEmpty
      ? 0.0
      : _tasks.where((task) => task.isCompleted).length / _tasks.length;
  Map<DateTime, List<Map<String, dynamic>>> get heatmapData => _heatmapData;
  Color get heatmapColor => _heatmapColor;
  DateTime? get heatmapStartDate => _heatmapStartDate;
  DateTime? get heatmapEndDate => _heatmapEndDate;

  // --- Initialization and Data Fetching ---
  Future<void> _initialize() async {
    _isLoading = true;
    Future.microtask(() => notifyListeners());

    await Future.wait([
      _fetchTasks(),
      fetchHeatmapData(notify: false),
      loadHeatmapColor(notify: false),
    ]);

    _isLoading = false;
    Future.microtask(() => notifyListeners());
  }

  Future<void> _fetchTasks() async {
    _tasks = await _taskService.getTasks(_notionDatabaseId);
  }

  Future<void> fetchHeatmapData({bool notify = true}) async {
    _heatmapData = await _taskService.getHeatmapData();
    _calculateHeatmapDateRange();
    if (notify) {
      Future.microtask(() => notifyListeners());
    }
  }

  Future<void> loadHeatmapColor({bool notify = true}) async {
    _heatmapColor = await _settingsService.getHeatmapColor();
    if (notify) {
      Future.microtask(() => notifyListeners());
    }
  }

  // --- Business Logic ---
  void _calculateHeatmapDateRange() {
    final datasets = _heatmapData.map(
      (date, records) => MapEntry(date, records.length),
    );
    final DateTime endDate = DateTime.now();

    if (datasets.isEmpty) {
      _heatmapStartDate = endDate.subtract(const Duration(days: 90));
    } else {
      final DateTime earliestDate = datasets.keys.reduce(
        (a, b) => a.isBefore(b) ? a : b,
      );
      final int daysDifference = endDate.difference(earliestDate).inDays;

      if (daysDifference < 90) {
        _heatmapStartDate = endDate.subtract(const Duration(days: 90));
      } else {
        final int totalDays = (daysDifference / 7).ceil() * 7;
        _heatmapStartDate = endDate.subtract(Duration(days: totalDays - 1));
      }
    }
    _heatmapEndDate = endDate;
  }

  Future<void> toggleTaskCompletion(String taskId) async {
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      _tasks[taskIndex].isCompleted = !_tasks[taskIndex].isCompleted;
      Future.microtask(() => notifyListeners());
    }
  }

  Future<void> addStudyRecordForToday({
    String? databaseName,
    required String title,
  }) async {
    await _taskService.addStudyRecordForToday(
      databaseName: databaseName,
      title: title,
    );
    await fetchHeatmapData();
  }
}
