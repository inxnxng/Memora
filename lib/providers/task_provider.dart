import 'package:flutter/widgets.dart';
import 'package:memora/domain/usecases/task_usecases.dart';
import 'package:memora/models/task_model.dart';
import 'package:memora/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TaskProvider with ChangeNotifier {
  final TaskUsecases _taskUsecases;

  List<Task> _tasks = [];
  AppUser? _user;
  bool _isLoading = true;
  DateTime? _roadmapStartDate;

  TaskProvider({required TaskUsecases taskUsecases})
    : _taskUsecases = taskUsecases {
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
    await _fetchAndLoadTasks();
    _isLoading = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.microtask(() => notifyListeners());
      });
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

  Future<void> _fetchAndLoadTasks() async {
    _tasks = await _taskUsecases.fetchTasks();

    // Load lastTrainedDate for each task
    for (var task in _tasks) {
      task.lastTrainedDate = await _taskUsecases.loadLastTrainedDate(task.id);
    }
    await _updateUserProgress();
  }

  Future<void> toggleTaskCompletion(String taskId) async {
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      _tasks[taskIndex].isCompleted = !_tasks[taskIndex].isCompleted;
      await _taskUsecases.toggleTaskCompletion(
        taskId,
        _tasks[taskIndex].isCompleted,
      );
      await _updateUserProgress();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.microtask(() => notifyListeners());
        });
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.microtask(() => notifyListeners());
      });
    });
  }
}
