import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:memora/constants/task_list.dart';
import 'package:memora/models/task_model.dart';
import 'package:memora/models/user_model.dart';
import 'package:memora/providers/notion_provider.dart';
import 'package:memora/services/firebase_service.dart';
import 'package:memora/services/local_storage_service.dart'; // New import
import 'package:shared_preferences/shared_preferences.dart';

class TaskProvider with ChangeNotifier {
  final FirebaseService _firebaseService;
  final NotionProvider _notionProvider;
  final LocalStorageService _localStorageService; // New field
  List<Task> _tasks = [];
  AppUser? _user;
  bool _isLoading = true;
  final int totalDays = 30;
  DateTime? _roadmapStartDate;

  TaskProvider(
    this._firebaseService,
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
    await _firebaseService.signInAnonymously();
    await _fetchUser();
    await _loadRoadmapStartDate();
    await _fetchTasks();
    _isLoading = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<void> _fetchUser() async {
    _user = await _firebaseService.getCurrentUser();
  }

  Future<void> _loadRoadmapStartDate() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('roadmap_start_date');
    if (timestamp != null) {
      _roadmapStartDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
  }

  Future<void> _saveRoadmapStartDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('roadmap_start_date', date.millisecondsSinceEpoch);
    _roadmapStartDate = date;
  }

  Future<void> _fetchTasks() async {
    if (_notionProvider.isConnected) {
      try {
        _tasks = await _notionProvider.fetchRoadmapTasks();
        if (_tasks.isNotEmpty) {
          // Optionally, save Notion tasks to Firebase for offline access/consistency
          await _firebaseService.saveTasks(_tasks);
        }
      } catch (e) {
        debugPrint('Failed to fetch tasks from Notion: $e');
        // Fallback to local generation if Notion fails
        await _generateAndSaveDailyTasks();
      }
    }

    if (_tasks.isEmpty) {
      // If Notion is not connected or returned no tasks, generate locally
      await _generateAndSaveDailyTasks();
    }

    // Load lastTrainedDate for each task
    for (var task in _tasks) {
      task.lastTrainedDate = await _localStorageService.loadLastTrainedDate(
        task.id,
      );
    }
    await _updateUserProgress();
  }

  Future<void> _generateAndSaveDailyTasks() async {
    if (_roadmapStartDate == null) {
      await _saveRoadmapStartDate(DateTime.now());
    }
    final random = Random();
    _tasks = List.generate(totalDays, (index) {
      final taskDetail = dailyTasks[random.nextInt(dailyTasks.length)];
      return Task(
        id: 'day${index + 1}',
        title: 'Day ${index + 1}: ${taskDetail['title']}',
        description: taskDetail['description'] ?? '',
        day: index + 1,
        lastTrainedDate: null, // Initialize as null for new tasks
      );
    });
    await _firebaseService.saveTasks(_tasks);
  }

  Future<void> toggleTaskCompletion(String taskId) async {
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      _tasks[taskIndex].isCompleted = !_tasks[taskIndex].isCompleted;
      await _firebaseService.updateTaskCompletion(
        taskId,
        _tasks[taskIndex].isCompleted,
      );
      await _updateUserProgress();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  Future<void> _updateUserProgress() async {
    if (_user != null) {
      await _firebaseService.updateUserProfile(_user!.displayName, progress);
    }
  }

  Future<void> updateUserName(String name) async {
    await _firebaseService.updateUserProfile(name, progress);
    await _fetchUser();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}
