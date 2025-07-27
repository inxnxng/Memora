import 'package:flutter/widgets.dart';
import 'package:memora/models/task_model.dart';
import 'package:memora/services/task_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TaskProvider with ChangeNotifier {
  final TaskService _taskService;
  final String? _notionDatabaseId;

  List<Task> _tasks = [];
  bool _isLoading = true;
  DateTime? _roadmapStartDate;
  Map<DateTime, int> _heatmapData = {};

  TaskProvider({required TaskService taskService, String? notionDatabaseId})
    : _taskService = taskService,
      _notionDatabaseId = notionDatabaseId {
    _initialize();
  }

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  double get progress => _tasks.isEmpty
      ? 0.0
      : _tasks.where((task) => task.isCompleted).length / _tasks.length;
  Map<DateTime, int> get heatmapData => _heatmapData;

  int get currentRoadmapDay {
    if (_roadmapStartDate == null) return 1;
    final now = DateTime.now();
    final difference = now.difference(_roadmapStartDate!).inDays;
    return difference + 1; // Day 1 is 0 difference
  }

  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    await _loadRoadmapStartDate();
    _tasks = await _taskService.getTasks(_notionDatabaseId);
    await fetchHeatmapData();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadRoadmapStartDate() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('roadmap_start_date');
    if (timestamp != null) {
      _roadmapStartDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
  }

  Future<void> toggleTaskCompletion(String taskId) async {
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      final task = _tasks[taskIndex];
      task.isCompleted = !task.isCompleted;
      // The business logic for this is now implicitly handled by state change.
      // If remote state needed to be updated, a call to _taskService would be here.
      notifyListeners();
    }
  }

  Future<void> addStudyRecordForToday() async {
    await _taskService.addStudyRecordForToday();
    await fetchHeatmapData(); // Refresh heatmap data after adding a new record
  }

  Future<void> fetchHeatmapData() async {
    _heatmapData = await _taskService.getHeatmapData();
    notifyListeners();
  }
}
