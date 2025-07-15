import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // New import for DateFormat
import 'package:memora/providers/task_provider.dart';
import 'package:memora/screens/profile_screen.dart';
import 'package:memora/screens/ranking_screen.dart';
import 'package:memora/screens/task_screen.dart';
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

  @override
  void initState() {
    super.initState();
    // Scroll to the current day after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      _itemScrollController.scrollTo(
        index: taskProvider.currentRoadmapDay - 1, // 0-indexed
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        alignment: 0.5, // Center the item
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final int totalDays = 30; // Total days in the roadmap

    return Scaffold(
      appBar: AppBar(
        title: const Text('기억력 훈련 로드맵'),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            onPressed: () {
              if (taskProvider.user?.displayName == null ||
                  taskProvider.user!.displayName.isEmpty) {
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

            final isFuture = dayNumber > taskProvider.currentRoadmapDay;

            return SizedBox(
              width: itemWidth,
              child: InkWell(
                onTap: isFuture
                    ? null // Disable tap for future dates
                    : () {
                        if (task != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TaskScreen(task: task),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Day $dayNumber is not yet available.',
                              ),
                            ),
                          );
                        }
                      },
                child: Opacity(
                  opacity: isFuture ? 0.5 : 1.0, // Dim future dates
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
