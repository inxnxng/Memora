import 'dart:math';

import 'package:memora/constants/task_list.dart';
import 'package:memora/domain/repositories/notion_repository.dart';
import 'package:memora/domain/repositories/task_repository.dart';
import 'package:memora/models/task_model.dart';
import 'package:memora/services/local_storage_service.dart';

class TaskRepositoryImpl implements TaskRepository {
  final NotionRepository _notionRepository;
  final LocalStorageService _localStorageService;
  final int totalDays = 30;

  TaskRepositoryImpl(this._notionRepository, this._localStorageService);

  @override
  Future<List<Task>> fetchTasks() async {
    List<Task> fetchedTasks = [];
    // Assuming NotionRepository has a way to check connection or handles it internally
    try {
      fetchedTasks = await _notionRepository
          .getRoadmapTasksFromDB('YOUR_NOTION_DATABASE_ID')
          .then(
            (notionPages) =>
                notionPages.map((json) => Task.fromNotion(json)).toList(),
          );
    } catch (e) {
      // If Notion fails, fetchedTasks remains empty, triggering local generation
    }

    if (fetchedTasks.isEmpty || fetchedTasks.length < totalDays) {
      // If Notion didn't provide enough tasks, generate/fill locally
      final Map<int, Task> existingTasks = {
        for (var task in fetchedTasks) task.day: task,
      };
      final generatedTasks = List<Task>.generate(totalDays, (index) {
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
      fetchedTasks = generatedTasks;
    }

    // Ensure tasks are sorted by day
    fetchedTasks.sort((a, b) => a.day.compareTo(b.day));

    // Load lastTrainedDate for each task
    for (var task in fetchedTasks) {
      task.lastTrainedDate = await _localStorageService.loadLastTrainedDate(
        task.id,
      );
    }
    return fetchedTasks;
  }

  @override
  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) async {
    // In a real app, you might update Notion here as well
    // For now, only local state is managed by TaskProvider
  }

  @override
  Future<void> saveLastTrainedDate(String taskId, DateTime date) async {
    await _localStorageService.saveLastTrainedDate(taskId, date);
  }

  @override
  Future<DateTime?> loadLastTrainedDate(String taskId) async {
    return _localStorageService.loadLastTrainedDate(taskId);
  }
}
