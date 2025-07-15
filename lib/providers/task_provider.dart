import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:memora/constants/task_list.dart';
import 'package:memora/models/task_model.dart';
import 'package:memora/models/user_model.dart';
import 'package:memora/providers/notion_provider.dart';
/*import 'package:memora/services/firebase_service.dart';*/
import 'package:memora/services/local_storage_service.dart'; // New import
import 'package:shared_preferences/shared_preferences.dart';

class TaskProvider with ChangeNotifier {
  /*final FirebaseService _firebaseService;*/
  final NotionProvider _notionProvider;
  final LocalStorageService _localStorageService; // New field
  List<Task> _tasks = [];
  AppUser? _user;
  bool _isLoading = true;
  final int totalDays = 30;
  DateTime? _roadmapStartDate;

  TaskProvider(
    /*this._firebaseService,*/
    this._notionProvider,
    this._localStorageService,
  ) {
    // Updated constructor
    _initialize();
  }

  List<Task> get tasks => _tasks;
  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  double get progress => _tasks.isEmpty
      ? 0.0
      : _tasks.where((task) => task.isCompleted).length / _tasks.length;

  int get currentRoadmapDay {
    if (_roadmapStartDate == null) return 1;
    final now = DateTime.now();
    final difference = now.difference(_roadmapStartDate!).inDays;
    return difference + 1; // Day 1 is 0 difference
  }

  Future<void> _initialize() async {
    /*await _firebaseService.signInAnonymously();*/
    await _fetchUser();
    await _loadRoadmapStartDate();
    await _fetchTasks();
    _isLoading = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<void> _fetchUser() async {
    /*_user = await _firebaseService.getCurrentUser();*/
  }

  Future<void> _loadRoadmapStartDate() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('roadmap_start_date');
    if (timestamp != null) {
      _roadmapStartDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
  }

  Future<void> _fetchTasks() async {
    List<Task> fetchedTasks = [];
    if (_notionProvider.isConnected) {
      try {
        fetchedTasks = await _notionProvider.fetchRoadmapTasks();
      } catch (e) {
        debugPrint('Failed to fetch tasks from Notion: $e');
        // If Notion fails, fetchedTasks remains empty, triggering local generation
      }
    }

    if (fetchedTasks.isEmpty || fetchedTasks.length < totalDays) {
      // If Notion didn't provide enough tasks, generate/fill locally
      final Map<int, Task> existingTasks = {
        for (var task in fetchedTasks) task.day: task,
      };
      _tasks = List.generate(totalDays, (index) {
        final dayNumber = index + 1;
        if (existingTasks.containsKey(dayNumber)) {
          return existingTasks[dayNumber]!;
        } else {
          final taskDetail = dailyTasks[Random().nextInt(dailyTasks.length)];
          return Task(
            id: 'day$dayNumber',
            title: 'Day $dayNumber: ${taskDetail['title']}',
            description: taskDetail['description'] ?? '',
            day: dayNumber,
            isCompleted: false,
            lastTrainedDate: null,
          );
        }
      });
    } else {
      _tasks = fetchedTasks;
    }

    // Ensure tasks are sorted by day
    _tasks.sort((a, b) => a.day.compareTo(b.day));

    // Load lastTrainedDate for each task
    for (var task in _tasks) {
      task.lastTrainedDate = await _localStorageService.loadLastTrainedDate(
        task.id,
      );
    }
    await _updateUserProgress();
  }

  Future<void> toggleTaskCompletion(String taskId) async {
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      _tasks[taskIndex].isCompleted = !_tasks[taskIndex].isCompleted;
      /*await _firebaseService.updateTaskCompletion(
        taskId,
        _tasks[taskIndex].isCompleted,
      );*/
      await _updateUserProgress();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  Future<void> _updateUserProgress() async {
    if (_user != null) {
      /*await _firebaseService.updateUserProfile(_user!.displayName, progress);*/
    }
  }

  Future<void> updateUserName(String name) async {
    /*await _firebaseService.updateUserProfile(name, progress);*/
    await _fetchUser();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}
