import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memora/models/task_model.dart';
import 'package:memora/providers/task_provider.dart';
import 'package:memora/providers/user_provider.dart';
import 'package:memora/screens/profile/profile_screen.dart';
import 'package:memora/screens/ranking/ranking_screen.dart';
import 'package:memora/screens/roadmap/task_screen.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class RoadmapScreen extends StatefulWidget {
  const RoadmapScreen({super.key});

  @override
  State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  bool _initialScrollScheduled = false;

  // Define milestones for the roadmap
  static const List<Map<String, dynamic>> _milestones = [
    {'day': 1, 'description': '기억력 훈련 시작!'},
    {'day': 5, 'description': '기본 개념 숙달'},
    {'day': 10, 'description': '단기 기억력 강화'},
    {'day': 15, 'description': '장기 기억력 훈련 시작'},
    {'day': 20, 'description': '복합 기억 훈련'},
    {'day': 25, 'description': '실전 적용 연습'},
    {'day': 30, 'description': '로드맵 완료!'},
  ];

  String _getMilestoneDescription(int day) {
    for (var milestone in _milestones) {
      if (milestone['day'] == day) {
        return milestone['description'] as String;
      }
    }
    return '';
  }

  Task? _findTaskForDay(List<Task> tasks, int dayNumber) {
    try {
      return tasks.firstWhere((t) => t.day == dayNumber);
    } catch (e) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final int totalDays = 30; // Total days in the roadmap

    if (taskProvider.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('기억력 훈련 로드맵')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_initialScrollScheduled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _itemScrollController.scrollTo(
            index: taskProvider.currentRoadmapDay - 1, // 0-indexed
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            alignment: 0.5, // Center the item
          );
        }
      });
      _initialScrollScheduled = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('기억력 훈련 로드맵'),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            onPressed: () {
              final userProvider = context.read<UserProvider>();
              if (userProvider.displayName == null ||
                  userProvider.displayName!.isEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RankingScreen(),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ScrollablePositionedList.builder(
          scrollDirection: Axis.horizontal,
          itemScrollController: _itemScrollController,
          itemPositionsListener: _itemPositionsListener,
          itemCount: totalDays, // Display 30 days
          itemBuilder: (context, index) {
            final int dayNumber = index + 1; // Day numbers start from 1
            final task = taskProvider.tasks.length > index
                ? taskProvider.tasks[index]
                : null;

            final isToday = dayNumber == taskProvider.currentRoadmapDay;
            final milestoneDescription = _getMilestoneDescription(dayNumber);

            // Increase item size
            final double itemWidth = isToday ? 140 : 120; // Increased width
            final double dayFontSize = isToday ? 16 : 14; // Increased font size
            final double dateFontSize = isToday
                ? 12
                : 10; // Increased font size

            String? formattedDate;
            if (task?.lastTrainedDate != null) {
              formattedDate = DateFormat(
                'yy.MM.dd',
              ).format(task!.lastTrainedDate!); // Format date
            }

            final bool isLocked;
            if (dayNumber > 1) {
              // Find the task for the previous day
              final previousDayTask = _findTaskForDay(
                taskProvider.tasks,
                dayNumber - 1,
              );
              // Lock if the previous day's task doesn't exist or isn't completed
              isLocked =
                  previousDayTask == null || !previousDayTask.isCompleted;
            } else {
              // Day 1 is never locked
              isLocked = false;
            }

            return SizedBox(
              width: itemWidth,
              child: InkWell(
                onTap: isLocked
                    ? null // Disable tap for locked dates
                    : () {
                        final taskForDay = _findTaskForDay(
                          taskProvider.tasks,
                          dayNumber,
                        );
                        if (taskForDay != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  TaskScreen(task: taskForDay),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Task for Day $dayNumber is not available yet.',
                              ),
                            ),
                          );
                        }
                      },
                child: Opacity(
                  opacity: isLocked ? 0.5 : 1.0, // Dim locked dates
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform.scale(
                        scale: isToday ? 1.2 : 1.0, // Make today's icon larger
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: task?.isCompleted == true
                                ? Colors.green
                                : (isToday
                                      ? Colors.blue.shade100
                                      : Colors.grey.shade300),
                            shape: BoxShape.circle,
                            border: isToday
                                ? Border.all(color: Colors.blue, width: 2)
                                : null,
                          ),
                          child: Icon(
                            task?.isCompleted == true
                                ? Icons.check
                                : Icons.lightbulb_outline,
                            color: task?.isCompleted == true
                                ? Colors.white
                                : Colors.black54,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Day $dayNumber',
                        style: TextStyle(fontSize: dayFontSize),
                      ),
                      if (formattedDate != null)
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: dateFontSize,
                            color: Colors.grey[600],
                          ),
                        ),
                      if (milestoneDescription.isNotEmpty)
                        Text(
                          milestoneDescription,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isToday ? 12 : 10,
                            color: isToday ? Colors.blue : Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
